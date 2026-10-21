# Plugins that call Kotlin code through JNI (shared_preferences, path_provider).
# Without these rules R8 removes those methods in release builds and the app
# fails with NoSuchMethodError.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.coroutines.Continuation { *; }
