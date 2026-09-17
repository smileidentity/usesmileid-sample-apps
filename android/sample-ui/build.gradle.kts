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
    // The SDK, by its published coordinates exactly as a partner names it. An SDK repo substitutes
    // these for its own projects, which is what makes this module its public-API gate.
    // api, not implementation: UseSmileIDSampleThemeOverride has AdaptiveColor in its public
    // signature, so every consumer needs the SDK on its compile classpath to assign those fields.
    api(platform(libs.usesmileid.bom))
    api(libs.usesmileid)

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
    // Robolectric 4.17 reaches into OpenJDK internals, which are closed by default from JDK 17 on.
    jvmArgs(
        "--add-opens=java.base/java.lang=ALL-UNNAMED",
        "--add-opens=java.base/java.util=ALL-UNNAMED",
        "--add-opens=java.base/java.io=ALL-UNNAMED",
        "--add-opens=java.base/java.net=ALL-UNNAMED",
        "--add-opens=java.base/java.security=ALL-UNNAMED",
        "--add-opens=java.base/java.text=ALL-UNNAMED",
        "--add-opens=java.base/jdk.internal.access=ALL-UNNAMED",
        "--add-opens=java.desktop/java.awt.font=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
    )

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
