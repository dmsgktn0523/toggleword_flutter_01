# Proguard 설정 예시
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.example.toggleworld_flutter_01.** { *; }
-keep class org.jetbrains.kotlin.** { *; }

# Flutter 및 플러그인 관련 클래스 유지
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
