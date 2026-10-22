# ProGuard rules for Speed Math with AI

# Flutter core rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.material.**

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }
