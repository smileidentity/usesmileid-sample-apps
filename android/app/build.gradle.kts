import org.gradle.api.artifacts.component.ModuleComponentIdentifier
import org.gradle.api.artifacts.result.ResolvedArtifactResult
import org.gradle.api.artifacts.result.ResolvedComponentResult
import org.gradle.api.artifacts.result.ResolvedDependencyResult
import org.gradle.maven.MavenModule
import org.gradle.maven.MavenPomArtifact
import org.gradle.process.ExecOperations
import org.w3c.dom.Element
import javax.inject.Inject
import javax.xml.parsers.DocumentBuilderFactory
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

    val uploadKeystore = file("upload.jks")
    val versionCodeProperty = findProperty("VERSION_CODE")?.toString()

    if (findProperty("REQUIRE_UPLOAD_SIGNING")?.toString().toBoolean()) {
        if (!uploadKeystore.exists()) {
            throw GradleException("upload.jks is missing; refusing to build a debug-signed release")
        }
        if (versionCodeProperty.isNullOrBlank()) {
            throw GradleException("VERSION_CODE is required when REQUIRE_UPLOAD_SIGNING is set")
        }
    }

    defaultConfig {
        applicationId = "com.usesmileid.sample.android"
        minSdk = 24
        targetSdk = 37
        versionCode = versionCodeProperty?.let { raw ->
            raw.toIntOrNull()?.takeIf { it > 0 }
                ?: throw GradleException("VERSION_CODE must be a positive integer, got '$raw'")
        } ?: 1
        versionName = "1.0.1"
    }

    signingConfigs {
        if (uploadKeystore.exists()) {
            create("upload") {
                val uploadKeystorePassword = findProperty("uploadKeystorePassword") as? String
                storeFile = uploadKeystore
                keyAlias = "upload"
                storePassword = uploadKeystorePassword
                keyPassword = uploadKeystorePassword
            }
        }
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = signingConfigs.getByName(if (uploadKeystore.exists()) "upload" else "debug")
        }
    }

    bundle {
        abi { enableSplit = true }
        density { enableSplit = true }
        language { enableSplit = false }
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
    inputs.dir(layout.projectDirectory.dir("../play"))
        .withPropertyName("listingCopy")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    inputs.file(layout.projectDirectory.file("src/main/kotlin/com/usesmileid/sampleapps/android/navigation/TokenDestinations.kt"))
        .withPropertyName("simulateWiring")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}

/** Third-party notices from the RELEASE runtime classpath, which is what a partner ships. */
abstract class LicenseNotices : DefaultTask() {

    /** `coordinate<TAB>pom path`, empty where Gradle resolved none. */
    @get:Input
    abstract val pomLines: ListProperty<String>

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
    abstract val pomIndex: RegularFileProperty

    @get:Inject
    abstract val exec: ExecOperations

    @TaskAction
    fun run() {
        val file = pomIndex.get().asFile
        file.parentFile.mkdirs()
        file.writeText(pomLines.get().joinToString("\n", postfix = "\n"))
        exec.exec {
            commandLine(
                buildList {
                    add("python3")
                    add(generator.get().asFile.absolutePath)
                    add("--poms")
                    add(file.absolutePath)
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

/**
 * Resolves every module's POM and each parent up its chain. Gradle must do it: a module published with
 * Gradle Module Metadata resolves from its `.module` and never fetches the `.pom`, so reading the
 * cache directly passed here and failed on a clean runner.
 */
fun resolvePomIndex(coordinates: List<String>): List<String> {
    val index = linkedMapOf<String, String>()
    var wanted = coordinates.toSet()
    // Parents are separate modules, so each round can reveal the next one up the chain.
    repeat(POM_PARENT_ROUNDS) {
        val missing = wanted.filterNot(index::containsKey)
        if (missing.isEmpty()) return@repeat
        val resolved = missing.mapNotNull { coordinate ->
            val (group, name, version) = coordinate.split(":")
            dependencies.createArtifactResolutionQuery()
                .forModule(group, name, version)
                .withArtifacts(MavenModule::class.java, MavenPomArtifact::class.java)
                .execute()
                .resolvedComponents
                .flatMap { it.getArtifacts(MavenPomArtifact::class.java) }
                .filterIsInstance<ResolvedArtifactResult>()
                .firstOrNull()
                ?.let { coordinate to it.file }
        }.toMap()
        index.putAll(resolved.mapValues { it.value.absolutePath })
        // Recorded rather than dropped, so the generator can name what it could not read.
        missing.filterNot(resolved::containsKey).forEach { index[it] = "" }
        wanted = resolved.values.flatMap(::pomParents).toSet()
    }
    return index.map { "${it.key}\t${it.value}" }
}

/** The parent coordinate only; the authoritative POM read is the generator's. */
fun pomParents(pom: File): List<String> {
    // Namespace-unaware by default, which is what keeps the tag names unprefixed.
    val document = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(pom)
    val parent = document.getElementsByTagName("parent").item(0) as? Element ?: return emptyList()
    val coordinate = listOf("groupId", "artifactId", "version").map { field ->
        parent.getElementsByTagName(field).item(0)?.textContent?.trim().orEmpty()
    }
    return if (coordinate.any(String::isEmpty)) emptyList() else listOf(coordinate.joinToString(":"))
}

/** A POM chain deeper than this is a broken publication, not something to keep querying for. */
val POM_PARENT_ROUNDS = 8

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
        // Resolved when the task reads it, not while configuring: every build would pay otherwise.
        val poms = provider { resolvePomIndex(modules.get()) }
        val asset = layout.projectDirectory.file("../sample-ui/src/main/assets/licenses.json")
        val script = layout.projectDirectory.file("../../scripts/generate_licenses.py")
        val texts = layout.projectDirectory.dir("../../scripts/license-texts")

        tasks.register<LicenseNotices>("generateLicenses") {
            description = "Regenerates sample-ui's third-party notices from the release runtime classpath."
            // Never skipped: the asset is no output here, because the check task takes it as input.
            outputs.upToDateWhen { false }
            pomLines.set(poms)
            check.set(false)
            generator.set(script)
            licenseTexts.set(texts)
            notices.set(asset)
            pomIndex.set(layout.buildDirectory.file("licenses/poms.tsv"))
            notCompatibleWithConfigurationCache("resolves POM artifacts for the licence scan")
        }

        tasks.register<LicenseNotices>("checkLicenses") {
            description = "Fails when the committed third-party notices no longer match the release classpath."
            // Never skipped: an edited asset with an unchanged classpath would pass on staleness.
            outputs.upToDateWhen { false }
            pomLines.set(poms)
            check.set(true)
            generator.set(script)
            licenseTexts.set(texts)
            notices.set(asset)
            pomIndex.set(layout.buildDirectory.file("licenses/checked-poms.tsv"))
            notCompatibleWithConfigurationCache("resolves POM artifacts for the licence scan")
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
    // The launch-intent parser needs a real Intent and Uri, which is the only reason this is here.
    testImplementation(libs.robolectric)
}
