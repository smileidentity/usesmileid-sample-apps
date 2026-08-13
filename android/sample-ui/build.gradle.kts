import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

// AGP 9 brings Kotlin support built in, so there is no `kotlin-android` plugin to apply.
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
}

android {
    // Fixed by spec/app-identity.json → sharedLibraryIdentity.androidNamespace. This library
    // runs under eight application identities, so it must never read one.
    namespace = "com.usesmileid.sampleapps.ui"
    compileSdk = 37

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = false
    }
}

tasks.withType<KotlinJvmCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)

    testImplementation(libs.junit)
}

// The `sample_*` ids are a cross-app contract, so the unit test asserts this module's constants
// against spec/test-ids.json rather than trusting them. Anchored on projectDir, not rootProject:
// an SDK repo consumes this module from its own build, where the root is somewhere else entirely.
tasks.withType<Test>().configureEach {
    systemProperty("sampleapps.spec.dir", layout.projectDirectory.dir("../../spec").asFile.absolutePath)
}
