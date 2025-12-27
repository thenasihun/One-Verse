import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nasihun.oneverse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nasihun.oneverse"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --------------- SIGNING -----------------
    val keystoreFilePath = keystoreProperties["storeFile"] as String?
    val sfile = keystoreFilePath?.let { file(it) }
    val alias = keystoreProperties["keyAlias"] as String?
    val password = keystoreProperties["keyPassword"] as String?
    val spasswords = keystoreProperties["storePassword"] as String?

    signingConfigs {
        create("release") {
            if (
                alias != null &&
                password != null &&
                spasswords != null &&
                sfile != null &&
                sfile.exists()
            ) {
                storeFile = sfile
                keyAlias = alias
                keyPassword = password
                storePassword = spasswords

                println("✔ Using release keystore")
            } else {
                println("⚠ Keystore not found. Release will use debug signing.")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = true 
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}