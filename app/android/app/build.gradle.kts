import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val qaKeystoreBase64 = providers.environmentVariable("MUSEMEND_ANDROID_KEYSTORE_BASE64").orNull
val qaStorePassword = providers.environmentVariable("MUSEMEND_ANDROID_STORE_PASSWORD").orNull
val qaKeyAlias = providers.environmentVariable("MUSEMEND_ANDROID_KEY_ALIAS").orNull
val qaKeyPassword = providers.environmentVariable("MUSEMEND_ANDROID_KEY_PASSWORD").orNull
val qaSigningConfigured = listOf(
    qaKeystoreBase64,
    qaStorePassword,
    qaKeyAlias,
    qaKeyPassword,
).all { !it.isNullOrBlank() }

val qaKeystoreFile = layout.buildDirectory
    .dir("qa-signing")
    .get()
    .asFile
    .resolve("musemend-upload.jks")

if (qaSigningConfigured && !qaKeystoreFile.exists()) {
    qaKeystoreFile.parentFile.mkdirs()
    qaKeystoreFile.writeBytes(Base64.getDecoder().decode(qaKeystoreBase64))
}

android {
    namespace = "com.musemend.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.musemend.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (qaSigningConfigured) {
        signingConfigs {
            create("qa") {
                storeFile = qaKeystoreFile
                storePassword = qaStorePassword
                keyAlias = qaKeyAlias
                keyPassword = qaKeyPassword
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (qaSigningConfigured) {
                signingConfig = signingConfigs.getByName("qa")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
