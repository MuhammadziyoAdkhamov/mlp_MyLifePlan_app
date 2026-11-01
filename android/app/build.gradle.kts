import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Google Services is applied only when the local Firebase config exists.
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Active MLP demo (lib/main.dart) works offline without Firebase credentials.
// A real Firebase build can provide android/app/google-services.json;
// this enables the Google Services plugin without committing that private file.
if (file("google-services.json").isFile) {
    apply(plugin = "com.google.gms.google-services")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties().apply {
    if (releaseKeyPropertiesFile.exists()) {
        releaseKeyPropertiesFile.inputStream().use { load(it) }
    }
}
val releaseStoreFile = releaseKeyProperties.getProperty("storeFile")
    ?.let { rootProject.file(it) }
val releaseSigningConfigured = releaseStoreFile?.isFile == true &&
    listOf("storePassword", "keyPassword", "keyAlias").all {
        !releaseKeyProperties.getProperty(it).isNullOrBlank()
    }

android {
    namespace = "uz.mylife.plan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        multiDexEnabled = true
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.mylife.plan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = requireNotNull(releaseStoreFile)
                storePassword = requireNotNull(
                    releaseKeyProperties.getProperty("storePassword"),
                )
                keyAlias = requireNotNull(
                    releaseKeyProperties.getProperty("keyAlias"),
                )
                keyPassword = requireNotNull(
                    releaseKeyProperties.getProperty("keyPassword"),
                )
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                null
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
