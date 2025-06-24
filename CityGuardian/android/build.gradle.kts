// File: android/build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// 🔹 Required first: buildscript block
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Firebase services plugin
        classpath("com.google.gms:google-services:4.3.15")
    }
}

// 🔹 Standard Gradle repo setup
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔹 Optional: custom output build directory (for monorepo or clean separation)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 🔹 Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
