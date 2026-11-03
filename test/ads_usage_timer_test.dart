import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gplx/core/constants/ad_units.dart';
import 'package:gplx/core/services/ads_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdsService service;
  late int fires;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fires = 0;
    service = AdsService();
    service.onThresholdReached = () => fires++;
    // Vào foreground mà không cần khởi tạo SDK thật.
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
  });

  tearDown(() => service.dispose());

  test('TC-01 [Boundary]: mặc định ngưỡng 10 phút (600s), 9m59s chưa hiện, đúng 10m00s hiện ngay', () {
    expect(service.usageThreshold, const Duration(minutes: 10));

    service.tick(const Duration(minutes: 9, seconds: 59));
    expect(fires, 0);
    expect(service.elapsed, const Duration(minutes: 9, seconds: 59));

    service.tick(const Duration(seconds: 1));
    expect(fires, 1);
    expect(service.elapsed, Duration.zero);
  });

  test('TC-02 [Multi-Cycle]: lặp lại chính xác qua 3 chu kỳ liên tiếp (10m -> 20m -> 30m)', () {
    service.tick(const Duration(minutes: 10));
    expect(fires, 1);
    expect(service.elapsed, Duration.zero);

    service.tick(const Duration(minutes: 9, seconds: 59));
    expect(fires, 1);
    service.tick(const Duration(seconds: 1));
    expect(fires, 2);
    expect(service.elapsed, Duration.zero);

    service.tick(const Duration(minutes: 10));
    expect(fires, 3);
    expect(service.elapsed, Duration.zero);
  });

  test('TC-03 [Lifecycle States]: không cộng thời gian ở inactive/hidden/paused, giữ nguyên số giây đã tích luỹ', () {
    service.tick(const Duration(minutes: 4));
    expect(service.elapsed, const Duration(minutes: 4));

    for (final bgState in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      service.didChangeAppLifecycleState(bgState);
      service.tick(const Duration(minutes: 60));
      expect(fires, 0);
      expect(service.elapsed, const Duration(minutes: 4));
    }

    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    service.tick(const Duration(minutes: 5, seconds: 59));
    expect(fires, 0);

    service.tick(const Duration(seconds: 1));
    expect(fires, 1);
    expect(service.elapsed, Duration.zero);
  });

  test('TC-04 [Exam Deferral + Overflow Carry-Over]: đang thi vượt 10p thì hoãn, thi xong hiện ngay và cộng dồn số phút dư sang chu kỳ kế tiếp', () async {
    final prefs = await SharedPreferences.getInstance();

    // Đã dùng 7 phút ngoài màn hình chính
    service.tick(const Duration(minutes: 7));
    expect(fires, 0);

    // Vào bài thi và làm bài suốt 5 phút 45 giây (tổng cộng 12 phút 45 giây -> dư 2 phút 45 giây)
    service.setExamActive(true);
    service.tick(const Duration(minutes: 5, seconds: 45));

    expect(fires, 0);
    expect(service.hasPendingAd, isTrue);
    expect(service.elapsed, const Duration(minutes: 12, seconds: 45));

    // Kết thúc bài thi -> hiện quảng cáo ngay lập tức và giữ lại 2 phút 45 giây cho chu kỳ tiếp theo
    service.setExamActive(false);
    await Future<void>.delayed(Duration.zero);

    expect(fires, 1);
    expect(service.hasPendingAd, isFalse);
    expect(service.elapsed, const Duration(minutes: 2, seconds: 45));
    expect(prefs.getInt(AdsService.accumulatedSecondsPrefKey), 2 * 60 + 45);

    // Chu kỳ tiếp theo chỉ cần thêm 7 phút 15 giây (10m - 2m45s) là hiện quảng cáo thứ 2
    service.tick(const Duration(minutes: 7, seconds: 14));
    expect(fires, 1);

    service.tick(const Duration(seconds: 1));
    expect(fires, 2);
    expect(service.elapsed, Duration.zero);
  });

  test('TC-05 [Multi-Threshold Overflow Cap]: làm bài thi liên tục 25 phút chỉ hiện 1 quảng cáo khi thoát và giữ lại 5 phút dư', () {
    service.setExamActive(true);
    service.tick(const Duration(minutes: 25));
    expect(fires, 0);
    expect(service.hasPendingAd, isTrue);

    service.setExamActive(false);
    expect(fires, 1);
    expect(service.hasPendingAd, isFalse);
    expect(service.elapsed, const Duration(minutes: 5));
  });

  test('TC-06 [Overlapping Exam Routes / pushReplacement]: làm lại bài thi không làm rò quảng cáo giữa chừng và bảo toàn phút dư', () {
    // Màn thi A mở và chạy tới phút 14 (dư 4 phút)
    service.setExamActive(true);
    service.tick(const Duration(minutes: 14));
    expect(service.hasPendingAd, isTrue);
    expect(fires, 0);

    // Người dùng bấm "Làm lại bài thi" (pushReplacement): Màn B initState trước khi Màn A dispose
    service.setExamActive(true);
    service.setExamActive(false); // Màn A dispose
    expect(service.examActive, isTrue);
    expect(fires, 0);
    expect(service.hasPendingAd, isTrue);

    // Làm tiếp ở Màn B thêm 4 phút nữa (tổng 18 phút -> dư 8 phút)
    service.tick(const Duration(minutes: 4));
    expect(fires, 0);

    // Đóng Màn B -> hiện 1 quảng cáo và giữ 8 phút dư
    service.setExamActive(false);
    expect(service.examActive, isFalse);
    expect(fires, 1);
    expect(service.hasPendingAd, isFalse);
    expect(service.elapsed, const Duration(minutes: 8));

    // Gọi dư setExamActive(false) không bị âm bộ đếm
    service.setExamActive(false);
    expect(service.examActive, isFalse);
  });

  test('TC-07 [Cross-Session Persistence]: cộng dồn chính xác qua nhiều lần đóng/mở app và bảo toàn phút dư khi tắt app lúc đang thi', () async {
    // Phiên 1: dùng 6 phút 30 giây rồi đóng app (paused)
    service.tick(const Duration(minutes: 6, seconds: 30));
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AdsService.accumulatedSecondsPrefKey), 6 * 60 + 30);

    // Phiên 2: mở lại app, kiểm tra restore idempotent, vào thi 8 phút (tổng 14m30s) rồi tắt ngang app
    final session2 = AdsService();
    int session2Fires = 0;
    session2.onThresholdReached = () => session2Fires++;
    await session2.restoreElapsedFromStorage();
    await session2.restoreElapsedFromStorage(); // Gọi lần 2 không bị nhân đôi
    expect(session2.elapsed, const Duration(minutes: 6, seconds: 30));

    session2.didChangeAppLifecycleState(AppLifecycleState.resumed);
    session2.setExamActive(true);
    session2.tick(const Duration(minutes: 8));
    expect(session2Fires, 0);
    expect(session2.hasPendingAd, isTrue);
    expect(session2.elapsed, const Duration(minutes: 14, seconds: 30));

    session2.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(prefs.getInt(AdsService.accumulatedSecondsPrefKey), 14 * 60 + 30);
    session2.dispose();

    // Phiên 3: mở lại app khi đã có 14m30s từ phiên trước -> hiện ad và giữ lại 4m30s dư
    final session3 = AdsService();
    int session3Fires = 0;
    session3.onThresholdReached = () => session3Fires++;
    await session3.restoreElapsedFromStorage();
    expect(session3.elapsed, const Duration(minutes: 14, seconds: 30));
    expect(session3.hasPendingAd, isTrue);

    session3.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(session3Fires, 1);
    expect(session3.hasPendingAd, isFalse);
    expect(session3.elapsed, const Duration(minutes: 4, seconds: 30));
    expect(prefs.getInt(AdsService.accumulatedSecondsPrefKey), 4 * 60 + 30);
    session3.dispose();
  });

  test('TC-08 [Offline Deferral & 60s Retry Cooldown]: mất mạng lúc 10p không mất thời gian, thử tải lại đúng mỗi 60s và cộng dồn phút dư khi có mạng lại', () {
    bool adReady = false;
    int loadAttempts = 0;
    service.adReadyOverride = () => adReady;
    service.onLoadAttempt = () => loadAttempts++;

    // Chạm mốc 10 phút khi chưa có mạng -> thử tải lần 1, giữ pending
    service.tick(const Duration(minutes: 10));
    expect(fires, 0);
    expect(service.hasPendingAd, isTrue);
    expect(service.elapsed, const Duration(minutes: 10));
    expect(loadAttempts, 1);

    // Sau 59 giây chưa đủ cooldown 60s -> chưa gọi tải lại, thời gian vẫn cộng dồn lên 10m59s
    service.tick(const Duration(seconds: 59));
    expect(loadAttempts, 1);
    expect(fires, 0);
    expect(service.elapsed, const Duration(minutes: 10, seconds: 59));

    // Đủ 60 giây -> thử tải lại lần 2
    service.tick(const Duration(seconds: 1));
    expect(loadAttempts, 2);
    expect(fires, 0);
    expect(service.elapsed, const Duration(minutes: 11));

    // Người dùng dùng thêm 2 phút 20 giây nữa (tổng 13m20s) thì mạng phục hồi và ad tải xong
    service.tick(const Duration(minutes: 2, seconds: 19));
    adReady = true;
    service.tick(const Duration(seconds: 1));

    expect(fires, 1);
    expect(service.hasPendingAd, isFalse);
    // Phút dư 3m20s được bảo toàn cho chu kỳ tiếp theo
    expect(service.elapsed, const Duration(minutes: 3, seconds: 20));
  });

  test('TC-09 [Full-Screen Ad Presentation Lifecycle]: dừng đồng hồ khi đang xem ad, bảo toàn phút dư qua Showed->Dismissed, và giữ nguyên 16p nếu show lỗi', () {
    final prodService = AdsService();
    prodService.adReadyOverride = () => true;
    prodService.didChangeAppLifecycleState(AppLifecycleState.resumed);

    // Giả lập tích luỹ 16 phút trong bài thi (dư 6 phút)
    prodService.setExamActive(true);
    prodService.tick(const Duration(minutes: 16));
    expect(prodService.hasPendingAd, isTrue);
    expect(prodService.elapsed, const Duration(minutes: 16));

    // Nhánh 1: Bắt đầu mở ad nhưng show thất bại (onAdFailedToShowFullScreenContent)
    prodService.beginAdPresentationForTest();
    prodService.handleAdFailedToShow();
    expect(prodService.hasPendingAd, isTrue);
    expect(prodService.elapsed, const Duration(minutes: 16));

    // Nhánh 2: Mở ad thành công (onAdShowedFullScreenContent)
    prodService.beginAdPresentationForTest();
    prodService.handleAdShowed();
    expect(prodService.hasPendingAd, isFalse);
    expect(prodService.elapsed, const Duration(minutes: 6));

    // Trong lúc người dùng đang xem quảng cáo 45 giây (_showingAd == true), đồng hồ không được cộng thêm
    prodService.tick(const Duration(seconds: 45));
    expect(prodService.elapsed, const Duration(minutes: 6));

    // Khi đóng quảng cáo (onAdDismissedFullScreenContent), 6 phút dư vẫn được giữ nguyên (không bị xoá về 0)
    prodService.handleAdDismissed();
    expect(prodService.elapsed, const Duration(minutes: 6));

    // Sau khi đóng quảng cáo, đồng hồ chạy tiếp bình thường
    prodService.tick(const Duration(minutes: 1));
    expect(prodService.elapsed, const Duration(minutes: 7));
    prodService.dispose();
  });

  test('TC-10 [Production Config & Manifest Integrity]: xác thực AdMob App ID, Interstitial Unit ID thật và app-ads.txt', () {
    // 1. Kiểm tra ID production cho bản release
    final prodInterstitialId = AdUnits.idFor(
      AdUnits.usageInterstitial,
      useTestIds: false,
      platform: TargetPlatform.android,
    );
    expect(prodInterstitialId, 'ca-app-pub-6640270625250590/1881200400');
    expect(prodInterstitialId, matches(r'^ca-app-pub-\d{16}/\d{10}$'));

    // 2. Kiểm tra ID test cho bản debug/profile trên Android & iOS
    expect(
      AdUnits.idFor(
        AdUnits.usageInterstitial,
        useTestIds: true,
        platform: TargetPlatform.android,
      ),
      'ca-app-pub-3940256099942544/1033173712',
    );
    expect(
      AdUnits.idFor(
        AdUnits.usageInterstitial,
        useTestIds: true,
        platform: TargetPlatform.iOS,
      ),
      'ca-app-pub-3940256099942544/4411468910',
    );

    // 3. Kiểm tra fail-safe khi truyền placement không tồn tại ở bản release
    expect(
      AdUnits.idFor('unknown_placement', useTestIds: false),
      isEmpty,
    );

    // 4. Kiểm tra hằng app-ads.txt và App ID production
    expect(
      AdUnits.appAdsTxtLine,
      'google.com, pub-6640270625250590, DIRECT, f08c47fec0942fa0',
    );
    expect(
      AdUnits.androidProdAppId,
      'ca-app-pub-6640270625250590~5872416303',
    );
    expect(AdUnits.kDebugAdIntervalSeconds, 30);
    expect(AdUnits.kReleaseAdIntervalSeconds, 600);
    expect(
      AdsService.instance.usageThreshold,
      const Duration(seconds: AdUnits.kDebugAdIntervalSeconds),
    );
    // 5. Đọc trực tiếp AndroidManifest.xml để đảm bảo APPLICATION_ID đã gắn đúng ID thật (dấu ~)
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    expect(manifestFile.existsSync(), isTrue);
    final manifestXml = manifestFile.readAsStringSync();
    expect(
      manifestXml.contains('android:name="com.google.android.gms.ads.APPLICATION_ID"'),
      isTrue,
    );
    expect(
      manifestXml.contains('android:value="ca-app-pub-6640270625250590~5872416303"'),
      isTrue,
    );
    expect(
      manifestXml.contains(AdUnits.androidTestAppId),
      isFalse,
    );
  });
}
