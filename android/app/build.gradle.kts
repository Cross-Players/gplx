// import java.util.Properties
// import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// val keystoreProperties = Properties()
// val keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// }

android {
    namespace = "com.crosstechedu.gplx"
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
        applicationId = "com.crosstechedu.gplx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.crosstechedu.gplx.dev"
            resValue("string", "app_name", "[D]Học GPLX Vạn Xuân")
        }
        create("stg") {
            dimension = "environment"
            applicationId = "com.crosstechedu.gplx.stg"
            resValue("string", "app_name", "[S]Học GPLX Vạn Xuân")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.crosstechedu.gplx"
            resValue("string", "app_name", "Học GPLX Vạn Xuân")
        }
    }

    //  signingConfigs {
    //     create("release") {
    //         keyAlias = keystoreProperties["keyAlias"] as String
    //         keyPassword = keystoreProperties["keyPassword"] as String
    //         storeFile = keystoreProperties["storeFile"]?.let { file(it) }
    //         storePassword = keystoreProperties["storePassword"] as String
    //     }
    // }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
