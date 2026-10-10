import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.isFile) {
    keyPropertiesFile.inputStream().use { input -> keyProperties.load(input) }
}
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested) {
    val requiredProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    val missingProperties = requiredProperties.filter {
        keyProperties.getProperty(it).isNullOrBlank()
    }
    if (missingProperties.isNotEmpty()) {
        throw GradleException(
            "Android release signing is not configured. Set " + missingProperties.joinToString() + " in android/key.properties."
        )
    }
    val releaseKeystore = rootProject.file(keyProperties.getProperty("storeFile"))
    if (!releaseKeystore.isFile) {
        throw GradleException("Android release keystore does not exist: " + releaseKeystore.path)
    }
}

android {
    namespace = "com.realestate.real_estate_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.realestate.real_estate_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storeFile = keyProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keyProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}