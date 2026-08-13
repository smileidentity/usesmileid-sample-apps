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

dependencyResolutionManagement {
    // Registry-only, permanently (AGENTS.md). No mavenLocal(), no flatDir, no path
    // substitution: the whole point of this repo is that it consumes the published SDK.
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
    }
}

rootProject.name = "UseSmileIDSampleAndroid"

enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

include(":app", ":sample-ui")
