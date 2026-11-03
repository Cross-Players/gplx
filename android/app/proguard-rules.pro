# AdMob / Google Mobile Ads SDK (google_mobile_ads 9.2.0) does not require
# any keep rules for the single interstitial ad we use. Empty file kept so the
# R8 minification step in `android/app/build.gradle.kts` can resolve its
# default proguard-rules.pro reference.
# Real AdMob publisher rules (if needed later) go here:
# -keep public class com.google.android.ads.** { public protected *; }
