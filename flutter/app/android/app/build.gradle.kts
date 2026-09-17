plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.usesmileid.sample.flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Taken as it stands per the 2026-09-17 ruling; see spec/app-identity.json.
        applicationId = "com.usesmileid.sample.flutter"
        // The floor the SDK's own native plugins set.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            // Signed with the debug keys so `flutter build apk --release` needs no keystore; this
            // app reaches no store, and the lane exists to prove the minified build.
            signingConfig = signingConfigs.getByName("debug")
            // No app-side keep rules, deliberately: a published artifact that needs one is a
            // finding against the SDK, and this is the configuration that surfaces it.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
