# Keep Firebase model classes
-keepclassmembers class com.aqarisyria.app.models.** {
    <fields>;
}

# Keep Firestore @DocumentId annotations
-keep class com.google.firebase.firestore.DocumentId

# Keep Gson/Json serialization
-keepattributes Signature
-keepattributes *Annotation*

# Keep Glide
-keep class com.bumptech.glide.** { *; }

# Keep Material Design
-dontwarn com.google.android.material.**
-keep class com.google.android.material.** { *; }
