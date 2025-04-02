plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.hive_ui"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "34.0.0"
    
    // Using the required NDK version for compatibility with all plugins
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hive_ui"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large app support
        multiDexEnabled = true
        
        // Optimize vector drawables
        vectorDrawables.useSupportLibrary = true
        
        // Enable resource shrinking
        resConfigs("en")
        
        // Add NDK ABI filters to reduce app size
        ndk {
            abiFilters.add("armeabi-v7a")
            abiFilters.add("arm64-v8a")
            abiFilters.add("x86_64")
        }
    }
    
    // Set up signing configuration for release
    signingConfigs {
        create("release") {
            // Check if we have keystore details from properties
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = java.util.Properties()
                keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
                
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            } else {
                // If no keystore, use debug signing for now
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Enable debugging for development builds
            isDebuggable = true
            
            // Disable R8 for faster debug builds
            isMinifyEnabled = false
            
            // Add Firebase Crashlytics mapping file
            firebaseCrashlytics {
                nativeSymbolUploadEnabled = false
                mappingFileUploadEnabled = false
            }
        }
        
        getByName("release") {
            // Use the release signing config
            try {
                signingConfig = signingConfigs.getByName("release")
            } catch (e: Exception) {
                // Fall back to debug signing if release signing is not available
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Enable R8 code shrinking and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use the standard ProGuard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Enable Firebase Crashlytics for release builds
            firebaseCrashlytics {
                nativeSymbolUploadEnabled = true
                mappingFileUploadEnabled = true
            }
        }
        
        // Add a profile build type for performance testing
        create("profile") {
            initWith(getByName("debug"))
            
            // Enable profiling
            isProfileable = true
            isMinifyEnabled = true
            isShrinkResources = false
            
            // Disable Crashlytics for profile builds
            firebaseCrashlytics {
                nativeSymbolUploadEnabled = false
                mappingFileUploadEnabled = false
            }
            
            // Disable debugging for profile builds
            isDebuggable = false
            
            matchingFallbacks.add("debug")
        }
    }
    
    // Configure split APKs for faster downloads
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = false
        }
    }
    
    // Optimize Bundle settings
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
    
    // Configure lint options to enforce code quality
    lint {
        checkReleaseBuilds = true
        abortOnError = false
    }
    
    // Packaging options to avoid conflicts
    packagingOptions {
        resources.excludes.add("META-INF/LICENSE")
        resources.excludes.add("META-INF/NOTICE")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    
    // Add multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Add lifecycle components with fixed versions
    implementation("androidx.lifecycle:lifecycle-viewmodel:2.6.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1")
    implementation("androidx.lifecycle:lifecycle-runtime:2.6.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.1")
    implementation("androidx.lifecycle:lifecycle-livedata:2.6.1")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.6.1")
    implementation("androidx.core:core-ktx:1.10.1")
    
    // Add Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics:18.4.3")
    implementation("com.google.firebase:firebase-analytics:21.3.0")
}

// Create an empty proguard-rules.pro file if it doesn't exist
afterEvaluate {
    val proguardFile = file("proguard-rules.pro")
    if (!proguardFile.exists()) {
        proguardFile.createNewFile()
        proguardFile.writeText("""
            # Add project specific ProGuard rules here.
            # Keep Flutter classes and methods
            -keep class io.flutter.** { *; }
            -keep class io.flutter.plugins.** { *; }
            -keep class io.flutter.plugin.** { *; }

            # Firebase
            -keep class com.google.firebase.** { *; }
            -keep class com.google.android.gms.** { *; }

            # Keep serializable classes
            -keepattributes Signature
            -keepattributes *Annotation*
            -keepattributes EnclosingMethod
            -keepattributes InnerClasses
        """.trimIndent())
    }
}
