import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.usesmileid.sampleapps.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.usesmileid.sampleapps.android"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        // The settings footer names the host application and its version.
        buildConfig = true
    }
}

tasks.withType<KotlinJvmCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

tasks.withType<Test>().configureEach {
    val specDir = layout.projectDirectory.dir("../../spec")
    systemProperty("sampleapps.spec.dir", specDir.asFile.absolutePath)
    // Declared so an edited spec or manifest re-runs the task; without them verify passes on a stale contract.
    inputs.dir(specDir).withPropertyName("specContract").withPathSensitivity(PathSensitivity.RELATIVE)
    inputs.file(layout.projectDirectory.file("src/main/AndroidManifest.xml"))
        .withPropertyName("manifestScheme")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}

dependencies {
    implementation(projects.sampleUi)

    implementation(platform(libs.usesmileid.bom))
    implementation(libs.usesmileid)
    implementation(libs.usesmileid.mlkit.face)
    implementation(libs.usesmileid.mlkit.document)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.navigation.compose)

    // The host owns a camera for the token QR (docs/plan/token-session-android.md §7.1). These are
    // already on the runtime classpath through the SDK; declaring them puts them on the compile one.
    implementation(libs.androidx.camera.camera2)
    implementation(libs.androidx.camera.compose)
    implementation(libs.androidx.camera.core)
    implementation(libs.androidx.camera.lifecycle)
    implementation(libs.mlkit.barcode.scanning)

    implementation(libs.destinations)
    ksp(libs.destinations.ksp)

    testImplementation(libs.junit)
}
