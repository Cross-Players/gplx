import 'package:flutter/foundation.dart';

/// App ID và ad unit ID của Google AdMob.
///
/// Call site KHÔNG dùng ID trực tiếp — luôn đi qua [AdUnits.idFor].
/// ID test lấy từ tài liệu chính thức của Google:
/// https://developers.google.com/admob/flutter/test-ads
class AdUnits {
  AdUnits._();

  // ===========================================================================
  // CẤU HÌNH CHU KỲ QUẢNG CÁO (TÙY CHỈNH NHANH ĐỂ TEST & REVIEW)
  // ===========================================================================
  /// Số giây dùng app để hiển thị 1 lần quảng cáo ở bản Debug / Máy ảo
  /// (dành cho Dev, QA và Reviewer test nhanh).
  /// Đổi trực tiếp con số này (ví dụ: 15, 30, 60) hoặc truyền
  /// `--dart-define=AD_INTERVAL_SECONDS=30` khi chạy app.
  static const int kDebugAdIntervalSeconds = 30;

  /// Số giây dùng app để hiển thị 1 lần quảng cáo ở bản Release / Store
  /// (`600` giây = **10 phút**).
  static const int kReleaseAdIntervalSeconds = 600;

  /// Ghi đè chu kỳ quảng cáo (tính bằng giây) qua `--dart-define=AD_INTERVAL_SECONDS=<giây>`
  /// hoặc trong `lib/env/*.json`. Nếu `> 0` sẽ ưu tiên dùng giá trị này.
  static const int kCustomAdIntervalSeconds = int.fromEnvironment(
    'AD_INTERVAL_SECONDS',
    defaultValue: 0,
  );

  /// Thời lượng chu kỳ quảng cáo thực tế áp dụng cho [AdsService.instance]:
  /// 1. Nếu có `--dart-define=AD_INTERVAL_SECONDS=<số_giây>` (> 0) -> dùng `<số_giây>`.
  /// 2. Nếu build `--release` (`kReleaseMode == true`) -> dùng [kReleaseAdIntervalSeconds] (600s = 10 phút).
  /// 3. Nếu chạy `--debug` / `--profile` (`!kReleaseMode`) -> dùng [kDebugAdIntervalSeconds] (30 giây).
  static const Duration defaultUsageThreshold = Duration(
        seconds: kCustomAdIntervalSeconds > 0
            ? kCustomAdIntervalSeconds
            : (kReleaseMode
                ? kReleaseAdIntervalSeconds
                : kDebugAdIntervalSeconds),
      );

  /// App ID TEST chính thức (Android).
  /// Dùng trong `android/app/src/main/AndroidManifest.xml`.
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';

  /// App ID PRODUCTION (Android) — lấy từ AdMob Console, dùng khi publish.
  /// Gán vào `android:value` của thẻ `<meta-data>` APPLICATION_ID trong manifest.
  static const String androidProdAppId =
      'ca-app-pub-6640270625250590~5872416303';

  /// App ID TEST chính thức (iOS) — dùng trong `ios/Runner/Info.plist`.
  static const String iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Interstitial TEST chính thức của Google.
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  /// true ở mọi build không phải release → luôn dùng ID test khi dev.
  static const bool kUseTestIds = !kReleaseMode;

  /// Khoá placement. Call site chỉ dùng hằng này.
  static const String usageInterstitial = 'usage_interstitial';

  /// ID thật. Điền sau khi tạo ad unit trên AdMob Console.
  static const Map<String, String> _productionIds = <String, String>{
    // Tạo ad unit "usage_interstitial_01" (Interstitial, Android) trên AdMob Console.
    usageInterstitial: 'ca-app-pub-6640270625250590/1881200400',
  };

  /// Dòng app-ads.txt cho publisher ID `pub-6640270625250590`.
  /// Host trên root domain của website developer (ví dụ: example.com/app-ads.txt).
  static const String appAdsTxtLine =
      'google.com, pub-6640270625250590, DIRECT, f08c47fec0942fa0';

  /// Điểm vào duy nhất: trả ID theo placement, hoặc '' nếu chưa cấu hình.
  /// Tuân theo [kUseTestIds] trừ khi [useTestIds] được truyền; chọn test ID theo [platform]
  /// (mặc định [defaultTargetPlatform]).
  static String idFor(String placement, {bool? useTestIds, TargetPlatform? platform}) {
    final bool useTests = useTestIds ?? kUseTestIds;
    final TargetPlatform plt = platform ?? defaultTargetPlatform;
    if (useTests) {
      return plt == TargetPlatform.iOS ? _testInterstitialIos : _testInterstitialAndroid;
    }
    return _productionIds[placement] ?? '';
  }
}
