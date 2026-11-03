import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gplx/core/constants/ad_units.dart';

/// Dịch vụ quảng cáo duy nhất của app.
///
/// Luật duy nhất: sau [usageThreshold] thời gian dùng app tích luỹ ở foreground
/// thì hiện một interstitial. Không hiện khi đang thi ([examActive]).
class AdsService with WidgetsBindingObserver {
  AdsService({this.usageThreshold = const Duration(minutes: 10)});

  // ===========================================================================
  // TÙY CHỈNH CHU KỲ QUẢNG CÁO (ĐƠN VỊ: GIÂY) ĐỂ TEST & REVIEW:
  // - Mặc định khi chạy Debug / Máy ảo: `30` giây/lần ([AdUnits.kDebugAdIntervalSeconds]).
  // - Mặc định khi build Release / Store: `600` giây = 10 phút/lần ([AdUnits.kReleaseAdIntervalSeconds]).
  // - Để đổi số giây khi test/review: sửa `kDebugAdIntervalSeconds` trong
  //   `lib/core/constants/ad_units.dart` (hoặc sửa trực tiếp `usageThreshold` bên dưới),
  //   hoặc truyền `--dart-define=AD_INTERVAL_SECONDS=<số_giây>`.
  // ===========================================================================
  static final AdsService instance = AdsService(
    usageThreshold: AdUnits.defaultUsageThreshold,
  );
  /// Khoá lưu số giây foreground tích luỹ trong SharedPreferences.
  static const String accumulatedSecondsPrefKey = 'admob_accumulated_seconds';

  /// Ngưỡng thời gian dùng app để hiện quảng cáo (mặc định 10 phút).
  Duration usageThreshold;

  /// Gọi mỗi khi đủ ngưỡng; dùng trong unit test để đếm số lần kích hoạt.
  void Function()? onThresholdReached;

  /// Hook phục vụ unit test để giả lập trạng thái sẵn sàng của quảng cáo.
  @visibleForTesting
  bool Function()? adReadyOverride;

  /// Hook phục vụ unit test để theo dõi số lần thử nạp quảng cáo.
  @visibleForTesting
  void Function()? onLoadAttempt;

  static const Duration _tickInterval = Duration(seconds: 1);
  static const int _persistIntervalSeconds = kReleaseMode ? 30 : 5;
  static const Duration _loadRetryCooldown = Duration(seconds: 60);
  static const Duration _maxAdAge = Duration(minutes: 55);
  bool _consumedCurrentShow = false;

  Duration _elapsed = Duration.zero;
  int _ticksSincePersist = 0;
  Duration _sinceLastLoadAttempt = _loadRetryCooldown;
  Timer? _ticker;
  bool _foreground = false;
  bool _pending = false;
  bool _showingAd = false;
  bool _disposed = false;
  bool _initialized = false;
  bool _sdkInitialized = false;
  bool _restored = false;
  bool _observerAdded = false;
  bool _nonPersonalized = true;

  InterstitialAd? _interstitial;
  DateTime? _adLoadedAt;
  bool _loading = false;

  int _activeExamCount = 0;

  /// true khi người dùng đang ở trong ít nhất một màn hình bài thi/ôn tập.
  bool get examActive => _activeExamCount > 0;

  /// Thời gian foreground đã tích luỹ (dùng cho test/telemetry).
  Duration get elapsed => _elapsed;

  /// Hiện đang ở foreground và đồng hồ đang chạy.
  bool get isForeground => _foreground;

  /// Đủ ngưỡng nhưng đang bị hoãn vì [examActive] hoặc vì quảng cáo chưa tải xong.
  bool get hasPendingAd => _pending;

  bool get _hasFreshAd {
    if (_interstitial == null || _adLoadedAt == null) return false;
    return DateTime.now().difference(_adLoadedAt!) < _maxAdAge;
  }

  bool get _isAdReady =>
      adReadyOverride?.call() ??
      (onThresholdReached != null ? true : _hasFreshAd);

  /// Đọc thời gian tích luỹ đã lưu từ [SharedPreferences] (idempotent).
  /// Bảo toàn toàn bộ số giây vượt ngưỡng (nếu phiên trước đang thi dở quá 10 phút)
  /// để sau khi hiện quảng cáo sẽ cộng dồn phần dư sang chu kỳ tiếp theo.
  Future<void> restoreElapsedFromStorage() async {
    if (_restored || _disposed) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSeconds = prefs.getInt(accumulatedSecondsPrefKey) ?? 0;
      if (savedSeconds > 0 && !_disposed) {
        _elapsed = Duration(seconds: savedSeconds);
        if (_elapsed >= usageThreshold) {
          _pending = true;
        }
      }
    } catch (e) {
      debugPrint('AdMob restore elapsed lỗi: $e');
    }
  }

  Future<void> _persistElapsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(accumulatedSecondsPrefKey, _elapsed.inSeconds);
    } catch (e) {
      debugPrint('AdMob persist elapsed lỗi: $e');
    }
  }

  /// Khởi tạo UMP consent rồi mới khởi tạo MobileAds.
  ///
  /// Không bao giờ ném lỗi ra ngoài: mọi lỗi được log và bỏ qua để không
  /// chặn app start.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;

    await restoreElapsedFromStorage();

    try {
      final consent = ConsentInformation.instance;
      await _requestConsentUpdate(consent, ConsentRequestParameters());
      await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null) {
          debugPrint('UMP form lỗi: ${formError.message}');
        }
      });
      _nonPersonalized = !await consent.canRequestAds();
    } catch (e) {
      // Consent không lấy được → coi như chưa có consent.
      _nonPersonalized = true;
      debugPrint('UMP consent lỗi: $e');
    }

    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('MobileAds initialize lỗi: $e');
    }

    if (_disposed) return;
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    _startClock();
  }

  Future<void> _requestConsentUpdate(
    ConsentInformation consent,
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();
    consent.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (formError) {
        debugPrint('UMP update lỗi: ${formError.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  // ---------------------------------------------------------------- đồng hồ

  void _startClock() {
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    if (_foreground) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(_tickInterval, (_) => tick(_tickInterval));
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _foreground;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startTicker();
      if (_pending && !examActive && !_showingAd) {
        _tryFire();
      }
    } else {
      _stopTicker();
      if (wasForeground) {
        unawaited(_persistElapsed());
      }
    }
  }

  /// Cộng thêm [delta] thời gian foreground. No-op khi đang background hoặc đang hiện ad.
  ///
  /// Tách khỏi `Timer` để test có thể tua thời gian mà không phải chờ thật.
  void tick(Duration delta) {
    if (_disposed || !_foreground || _showingAd) return;

    _elapsed += delta;
    _sinceLastLoadAttempt += delta;
    _ticksSincePersist += delta.inSeconds;

    if (_ticksSincePersist >= _persistIntervalSeconds) {
      _ticksSincePersist = 0;
      unawaited(_persistElapsed());
    }

    // Tự động nạp lại quảng cáo nền nếu lần nạp đầu lúc mở app bị lỗi mạng
    // hoặc quảng cáo cũ đã quá hạn 55 phút.
    if (!_isAdReady && !_loading && _sinceLastLoadAttempt >= _loadRetryCooldown) {
      _loadInterstitialIfNeeded();
    }

    if (_elapsed < usageThreshold && !_pending) return;

    if (examActive) {
      // Đang thi: hoãn, hiện ngay khi bài thi kết thúc; các phút vượt ngưỡng
      // tiếp tục được cộng dồn để chuyển sang chu kỳ 10 phút tiếp theo.
      _pending = true;
      return;
    }

    _tryFire();
  }

  void _tryFire() {
    if (_showingAd) return;

    if (!_isAdReady) {
      _pending = true;
      _loadInterstitialIfNeeded();
      return;
    }

    if (onThresholdReached != null) {
      _resetCounterAfterShow();
      onThresholdReached!.call();
      return;
    }

    unawaited(_showInterstitialSafely());
  }

  void _resetCounterAfterShow() {
    if (_elapsed >= usageThreshold && usageThreshold > Duration.zero) {
      _elapsed = Duration(
        microseconds: _elapsed.inMicroseconds % usageThreshold.inMicroseconds,
      );
    } else {
      _elapsed = Duration.zero;
    }
    _ticksSincePersist = 0;
    _pending = false;
    unawaited(_persistElapsed());
  }

  @visibleForTesting
  void beginAdPresentationForTest() {
    _showingAd = true;
    _consumedCurrentShow = false;
  }

  @visibleForTesting
  void handleAdShowed() {
    if (!_consumedCurrentShow) {
      _consumedCurrentShow = true;
      _resetCounterAfterShow();
    }
  }

  @visibleForTesting
  void handleAdDismissed() {
    _showingAd = false;
    if (!_consumedCurrentShow) {
      _consumedCurrentShow = true;
      _resetCounterAfterShow();
    }
  }

  @visibleForTesting
  void handleAdFailedToShow() {
    _showingAd = false;
    _pending = true;
    _loadInterstitialIfNeeded();
  }

  /// Bật/tắt cờ đang thi (có đếm tham chiếu khi chuyển chồng màn hình).
  /// Khi màn hình thi cuối cùng đóng lại sẽ hiện quảng cáo đang bị hoãn (nếu có).
  void setExamActive(bool value) {
    if (value) {
      _activeExamCount++;
    } else {
      if (_activeExamCount > 0) {
        _activeExamCount--;
      }
    }
    if (_activeExamCount == 0 && _pending && _foreground && !_showingAd) {
      _tryFire();
    }
  }

  // ------------------------------------------------------------ interstitial

  void _loadInterstitialIfNeeded() {
    if (_disposed || _loading) return;
    if (_interstitial != null && !_hasFreshAd) {
      _interstitial?.dispose();
      _interstitial = null;
      _adLoadedAt = null;
    }
    if (_interstitial != null) return;
    if (_sinceLastLoadAttempt < _loadRetryCooldown) return;

    _sinceLastLoadAttempt = Duration.zero;
    onLoadAttempt?.call();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (_disposed || !_sdkInitialized || _loading || _interstitial != null) {
      return;
    }

    final adUnitId = AdUnits.idFor(AdUnits.usageInterstitial);
    if (adUnitId.isEmpty) {
      debugPrint('AdMob: chưa cấu hình ad unit ID thật.');
      return;
    }

    _loading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(nonPersonalizedAds: _nonPersonalized),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          if (_disposed) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
          _adLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _interstitial = null;
          _adLoadedAt = null;
          debugPrint('AdMob load lỗi: ${error.message}');
        },
      ),
    );
  }

  Future<void> _showInterstitialSafely() async {
    if (!_hasFreshAd) {
      _pending = true;
      _loadInterstitialIfNeeded();
      return;
    }

    final ad = _interstitial!;
    _interstitial = null;
    _adLoadedAt = null;
    beginAdPresentationForTest();

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        handleAdShowed();
      },
      onAdDismissedFullScreenContent: (ad) {
        handleAdDismissed();
        ad.dispose();
        _sinceLastLoadAttempt = _loadRetryCooldown;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob show lỗi: ${error.message}');
        ad.dispose();
        handleAdFailedToShow();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('AdMob show exception: $e');
      ad.dispose();
      handleAdFailedToShow();
    }
  }

  /// Dọn tài nguyên. Gọi khi không dùng nữa.
  void dispose() {
    _disposed = true;
    _stopTicker();
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    _interstitial?.dispose();
    _interstitial = null;
    _adLoadedAt = null;
  }
}
