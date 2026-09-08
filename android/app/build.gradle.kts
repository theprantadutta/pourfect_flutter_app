import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing material, if it has been provided. Absent on a fresh clone
// and on CI until the secret is wired, which is why every use is null-checked.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties: Properties? = if (keystorePropertiesFile.exists()) {
    Properties().apply {
        keystorePropertiesFile.inputStream().use { stream -> load(stream) }
    }
} else {
    null
}

android {
    namespace = "com.example.pourfect_flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pranta.pourfect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release signing comes from android/key.properties, which is
        // gitignored and never committed. Drop the file and a keystore beside
        // it and release builds are signed properly with no code change.
        //
        //   storeFile=upload-keystore.jks
        //   storePassword=...
        //   keyAlias=upload
        //   keyPassword=...
        //
        // LOSING THAT KEYSTORE IS UNRECOVERABLE: Play will not accept an
        // update signed by anything else, so the app can never be updated
        // again under the same listing. Back it up somewhere that is not this
        // machine before the first upload.
        if (keystoreProperties != null) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Debug keys are a LOCAL CONVENIENCE so `flutter run --release`
            // works without a keystore. A build signed with them cannot be
            // published — Play rejects the debug certificate — so the fallback
            // is loud rather than silent.
            signingConfig = if (keystoreProperties != null) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "POURFECT: no android/key.properties — signing this " +
                        "release build with DEBUG keys. It cannot be uploaded to Play."
                )
                signingConfigs.getByName("debug")
            }

            // R8 renames Room's generated WorkDatabase_Impl, which WorkManager
            // then fails to instantiate by name — a crash that only appears in
            // a minified build. See proguard-rules.pro.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
