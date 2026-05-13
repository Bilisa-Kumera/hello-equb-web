# Flutter (keep required classes for reflection/engine)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Telebirr / EthiopiaPay SDK (AAR)
-keep class com.huawei.ethiopia.pay.sdk.** { *; }
-dontwarn com.huawei.ethiopia.pay.sdk.**

# Play Core / Feature Delivery (referenced by FlutterPlayStoreSplitApplication)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
