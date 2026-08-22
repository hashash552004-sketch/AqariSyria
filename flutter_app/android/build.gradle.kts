allprojects {
    repositories {
        // Regional mirror first: some ISPs block dl.google.com entirely.
        maven(url = "https://maven.aliyun.com/repository/google")
        google()
        mavenCentral()
    }
}

// Some legacy Flutter plugins (e.g. firebase_storage) declare their own
// buildscript repositories – make sure the regional mirror is visible there
// too, otherwise AGP resolution fails on networks that block dl.google.com.
subprojects {
    buildscript {
        repositories {
            maven(url = "https://maven.aliyun.com/repository/google")
            google()
            mavenCentral()
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
