plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hive_ui"
    compileSdk = flutter.compileSdkVersion
    // Using the required NDK version for compatibility with all plugins
    ndkVersion = "25.1.8937393"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Disable data binding temporarily to fix the issue
    buildFeatures {
        dataBinding = false
        viewBinding = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hive_ui"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// More targeted approach to fix dependency conflicts
configurations.all {
    resolutionStrategy {
        // Force specific versions for androidx dependencies
        force("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1")
        force("androidx.lifecycle:lifecycle-runtime-ktx:2.6.1")
        force("androidx.lifecycle:lifecycle-livedata-ktx:2.6.1")
        force("androidx.core:core-ktx:1.10.1")
        force("androidx.fragment:fragment-ktx:1.6.1")
        
        // Force stable version for the shared preferences plugin dependencies
        force("androidx.lifecycle:lifecycle-viewmodel:2.6.1")
        force("androidx.lifecycle:lifecycle-runtime:2.6.1")
        
        // Exclude the problematic 2.7.0 version completely
        exclude(group = "androidx.lifecycle", module = "lifecycle-viewmodel-ktx")
    }
}

// Clean task for corrupted cache if needed
tasks.register("cleanCache", Delete::class) {
    delete(fileTree("${System.getProperty("user.home")}/.gradle/caches/modules-2/files-2.1/androidx.lifecycle") {
        include("**/lifecycle-viewmodel-ktx-2.7.0*/**")
    })
}
