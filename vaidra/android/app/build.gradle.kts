plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vaidra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Changed from com.example.vaidra to unique package name for Play Store
        applicationId = "com.healthcare.vaidra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // WARNING: Using debug signing for development only
            // Before uploading to Play Store, you MUST:
            // 1. Generate a release keystore: keytool -genkey -v -keystore vaidra-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vaidra
            // 2. Create android/key.properties with your keystore details
            // 3. Update this configuration to use release signing
            // See RELEASE_SETUP.md for detailed instructions
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
