allprojects {
    repositories {
        google()
        mavenCentral()
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

// Use the installed SDK consistently for FlutterFire's Android libraries.
subprojects {
    if (name == "firebase_auth" || name == "firebase_core") { afterEvaluate {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()?.compileSdk = 36
        }
    }
}


