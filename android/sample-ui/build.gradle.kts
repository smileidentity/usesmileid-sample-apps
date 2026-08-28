import org.gradle.api.tasks.PathSensitivity
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
    alias(libs.plugins.ksp)
}

android {
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

    testOptions {
        // Robolectric inflates real resources.
        unitTests.isIncludeAndroidResources = true
    }
}

tasks.withType<KotlinJvmCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

// Where Room writes the schema JSON that future migrations are validated against. Committed.
ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}

dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.room.runtime)
    ksp(libs.androidx.room.compiler)
    implementation(libs.androidx.lifecycle.runtime.compose)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(platform(libs.androidx.compose.bom))
    testImplementation(libs.androidx.compose.ui.test.junit4)
    testImplementation(libs.robolectric)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}

tasks.withType<Test>().configureEach {
    val specDir = layout.projectDirectory.dir("../../spec")
    systemProperty("sampleapps.spec.dir", specDir.asFile.absolutePath)
    // Declared so an edited spec re-runs the task; without it verify passes on a stale contract.
    inputs.dir(specDir).withPropertyName("specContract").withPathSensitivity(PathSensitivity.RELATIVE)

    // Goldens render clock times, so the recorder's own zone and locale would otherwise bake into them.
    systemProperty("user.timezone", "UTC")
    systemProperty("user.language", "en")
    systemProperty("user.country", "US")

    // Declared so a changed golden invalidates the task; without it verify passes on a stale result.
    inputs.dir(layout.projectDirectory.dir("src/test/screenshots"))
        .withPropertyName("goldenScreenshots")
        .withPathSensitivity(PathSensitivity.RELATIVE)

    inputs.dir(layout.projectDirectory.dir("src/test/store-art"))
        .withPropertyName("storeArt")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}
