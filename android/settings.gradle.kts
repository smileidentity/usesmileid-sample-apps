pluginManagement {
    repositories {
        google {
            content {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.FAIL_ON_PROJECT_REPOS
    repositories {
        google {
            content {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
        // The SDK's snapshots, for a test build against its main branch: only Smile ID's own artifacts.
        maven("https://central.sonatype.com/repository/maven-snapshots/") {
            content { includeGroup("com.usesmileid") }
        }
    }
}

rootProject.name = "UseSmileIDSampleAndroid"

enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

include(":app", ":sample-ui")
