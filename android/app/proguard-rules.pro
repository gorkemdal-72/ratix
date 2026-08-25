# ─── FLUTTER ÇEKİRDEK KURALLARI ───
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── SUPABASE & NETWORK KURALLARI ───
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# ─── OKHTTP3 & UCROP & IMAGE PICKER ───
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.yalantis.ucrop.**
-keep class okhttp3.** { *; }
-keep class com.yalantis.ucrop.** { *; }

# ─── SERIALIZATION & REFLECTION ───
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ─── ANDROID DESUGARING & MULTIDEX ───
-keep class androidx.multidex.** { *; }
-dontwarn j$**
-dontwarn java.lang.invoke.**

# ─── FIREBASE & GOOGLE PLAY SERVICES ───
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─── MISSING CLASS WARNINGS ───
-ignorewarnings
