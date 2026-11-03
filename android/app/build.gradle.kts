import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// بارگذاری اطلاعات امضای Release از key.properties.
// این فایل و فایل keystore عمداً در .gitignore هستند و نباید عمومی شوند.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "ir.cr8v.tajhizyar"
    compileSdk = flutter.compileSdkVersion
    // نکته: ndkVersion عمداً حذف شد — اپ کد native ندارد و نبودِ آن
    // از دانلود خودکار ~2GB ای NDK توسط AGP جلوگیری می‌کند.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ir.cr8v.tajhizyar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // اگر key.properties و keystore موجود باشند → امضای Release واقعی؛
            // در غیر این صورت (کلون تازه بدون keystore) با کلید دیباگ ساخته
            // می‌شود تا بیلد نشکند — keystore واقعی فقط روی سیستم توسعه است.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            // لایه اعتبارسنجی Vulkan فقط برای دیباگ گرافیک است؛ روی گوشی واقعی
            // استفاده نمی‌شود و ~216MB از حجم APK و فایل‌های میانی می‌کاهد.
            excludes += "lib/**/libVkLayer_khronos_validation.so"
        }
    }
}

flutter {
    source = "../.."
}

// پلاگین Gradle فلاتر (forceNdkDownload) یک CMakeLists.txt خالی به ماژول app
// وصل می‌کند تا AGP را وادار به دانلود NDK کند. این اپ کد native ندارد و در
// سندباکس NDK واقعی وجود ندارد؛ تسک‌های CMake عملاً هیچ‌چیز تولید نمی‌کنند و
// بدون NDK واقعی شکست می‌خورند → غیرفعال می‌شوند. تمام کتابخانه‌های native
// (libflutter.so و پلاگین‌ها) از AARها و از طریق mergeNativeLibs وارد APK می‌شوند.
tasks.whenTaskAdded {
    if (name.contains("CMake")) {
        enabled = false
    }
}
