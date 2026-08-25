import org.gradle.api.artifacts.component.ModuleComponentIdentifier
import org.gradle.api.artifacts.result.ResolvedComponentResult
import org.gradle.api.artifacts.result.ResolvedDependencyResult
import org.gradle.process.ExecOperations
import javax.inject.Inject
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlin.serialization)
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

/**
 * Third-party notices, from the RELEASE runtime classpath because that is what a partner ships.
 * Gradle resolves; the rules live in `scripts/generate_licenses.py`, where they are tested.
 */
abstract class LicenseNotices : DefaultTask() {

    @get:Input
    abstract val coordinates: ListProperty<String>

    @get:Input
    abstract val check: Property<Boolean>

    @get:InputFile
    abstract val generator: RegularFileProperty

    @get:InputDirectory
    abstract val licenseTexts: DirectoryProperty

    /** The committed asset: an output when generating, the comparison target when checking. */
    @get:Internal
    abstract val notices: RegularFileProperty

    @get:OutputFile
    abstract val coordinateList: RegularFileProperty

    @get:Inject
    abstract val exec: ExecOperations

    @TaskAction
    fun run() {
        val list = coordinateList.get().asFile
        list.parentFile.mkdirs()
        list.writeText(coordinates.get().joinToString("\n", postfix = "\n"))
        exec.exec {
            commandLine(
                buildList {
                    add("python3")
                    add(generator.get().asFile.absolutePath)
                    add("--coordinates")
                    add(list.absolutePath)
                    add("--texts")
                    add(licenseTexts.get().asFile.absolutePath)
                    add("--out")
                    add(notices.get().asFile.absolutePath)
                    if (check.get()) add("--check")
                },
            )
        }
    }
}

// Through the variant API: the release runtime classpath does not exist until AGP creates the variant.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        // The GRAPH, not the artifacts: asking for files makes Gradle match attributes it need not.
        val modules = variant.runtimeConfiguration.incoming.resolutionResult.rootComponent.map { root ->
            val seen = linkedSetOf<String>()
            val walked = mutableSetOf<ResolvedComponentResult>()
            fun walk(component: ResolvedComponentResult) {
                if (!walked.add(component)) return
                (component.id as? ModuleComponentIdentifier)?.let {
                    seen += "${it.group}:${it.module}:${it.version}"
                }
                component.dependencies.filterIsInstance<ResolvedDependencyResult>()
                    .forEach { walk(it.selected) }
            }
            walk(root)
            seen.sorted()
        }
        val asset = layout.projectDirectory.file("../sample-ui/src/main/assets/licenses.json")
        val script = layout.projectDirectory.file("../../scripts/generate_licenses.py")
        val texts = layout.projectDirectory.dir("../../scripts/license-texts")

        tasks.register<LicenseNotices>("generateLicenses") {
            description = "Regenerates sample-ui's third-party notices from the release runtime classpath."
            // The asset it writes cannot be declared an output here — the check task takes it as input.
            // Never skipped, so an edited or deleted asset is rewritten rather than called up to date.
            outputs.upToDateWhen { false }
            coordinates.set(modules)
            check.set(false)
            generator.set(script)
            licenseTexts.set(texts)
            notices.set(asset)
            coordinateList.set(layout.buildDirectory.file("licenses/coordinates.txt"))
        }

        tasks.register<LicenseNotices>("checkLicenses") {
            description = "Fails when the committed third-party notices no longer match the release classpath."
            // The asset is this task's input and the other's output, so it cannot be declared here.
            // Never skipped: an edited asset with an unchanged classpath would pass on staleness.
            outputs.upToDateWhen { false }
            coordinates.set(modules)
            check.set(true)
            generator.set(script)
            licenseTexts.set(texts)
            notices.set(asset)
            coordinateList.set(layout.buildDirectory.file("licenses/checked-coordinates.txt"))
        }
    }
}

dependencies {
    implementation(projects.sampleUi)

    implementation(platform(libs.usesmileid.bom))
    implementation(libs.usesmileid)
    implementation(libs.usesmileid.mlkit.face)
    implementation(libs.usesmileid.mlkit.document)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.browser)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.navigation.compose)

    implementation(libs.androidx.camera.camera2)
    implementation(libs.androidx.camera.compose)
    implementation(libs.androidx.camera.core)
    implementation(libs.androidx.camera.lifecycle)
    implementation(libs.mlkit.barcode.scanning)

    implementation(libs.destinations)
    ksp(libs.destinations.ksp)

    implementation(libs.kotlinx.serialization.json)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.kotlinx.serialization)

    testImplementation(libs.junit)
}
