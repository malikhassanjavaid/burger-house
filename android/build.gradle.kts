allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.configureEach {
        // stripe_android's optional push-provisioning compileOnly module points
        // at Google's non-public TapAndPay artifact. Hungry Spot uses Stripe
        // card payments, not wallet push provisioning, so keep it off every
        // release/lint classpath while retaining the Stripe issuing stubs.
        exclude(
            group = "com.google.android.gms",
            module = "play-services-tapandpay",
        )
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
