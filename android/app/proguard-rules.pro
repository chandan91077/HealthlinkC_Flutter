# ─── Flutter ────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ─── Firebase Core / Firestore ───────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Prevent R8 from stripping Google Play Services Tasks needed by Firebase
-keep class com.google.android.gms.tasks.** { *; }

# ─── Firebase Messaging (FCM) ────────────────────────────────────────────────
-keep class com.google.firebase.messaging.** { *; }

# ─── Kotlin ──────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Lazy { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# ─── OkHttp / Dio (Networking) ───────────────────────────────────────────────
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okio.**
-keep class okio.** { *; }

# ─── Gson / JSON Serialization ───────────────────────────────────────────────
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# ─── Hive (Local Database) ───────────────────────────────────────────────────
-keep class com.hive.** { *; }
-keep class * extends com.hive.flutter.HiveObject { *; }

# ─── Razorpay ────────────────────────────────────────────────────────────────
-keepclassmembers class com.razorpay.** { *; }
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ─── Cashfree ────────────────────────────────────────────────────────────────
-keep class com.cashfree.** { *; }
-dontwarn com.cashfree.**

# ─── Image Picker / File Picker ──────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# ─── Permission Handler ──────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ─── Local Auth (Biometrics) ─────────────────────────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }

# ─── URL Launcher ────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ─── Keep model/data classes (prevent Gson/Hive stripping) ───────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ─── Reflection ──────────────────────────────────────────────────────────────
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ─── Misc ────────────────────────────────────────────────────────────────────
-dontwarn javax.xml.stream.XMLStreamException
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**