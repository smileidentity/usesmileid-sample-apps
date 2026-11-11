allprojects {
    repositories {
        google()
        mavenCentral()
        // The SDK snapshot pins timestamped com.usesmileid builds, which only this repository serves.
        maven("https://central.sonatype.com/repository/maven-snapshots/") {
            content { includeGroup("com.usesmileid") }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
