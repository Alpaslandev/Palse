# Flutter için temel kurallar
#-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
#-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Reflection kullanan kütüphaneler için
-keep class * implements java.io.Serializable { *; }

# Kendi uygulamanızın package'ı için (bunu kendi paket adınızla değiştirin)
# -keep class com.orderbros.palse.** { *; }