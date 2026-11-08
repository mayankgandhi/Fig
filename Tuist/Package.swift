// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    // Dependencies declare iOS floors from 12.0 to 17.0. Xcode 27 hard-rejects anything
    // below 15.0, and mixing floors fails too — a target built for iOS 17 cannot import a
    // module built for 26.0. So every externally-resolved target is pinned to the app's
    // own floor. `baseSettings` only reaches the project level and a target-level value
    // wins, so each target needs its own explicit entry.
    let iOSDeploymentTarget: SettingsDictionary = ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]

    let packageSettings = PackageSettings(
        // Anything carrying resources must be a dynamic framework. As a static framework
        // its resources are split into a synthesised `<Package>_<Target>` bundle target,
        // and that bundle keeps the dependency's own iOS 13 floor with no manifest hook
        // to override it.
        productTypes: [
            "Gate": .framework,
            "Telemetry": .framework,
            "DesignKit": .framework,
            "Roadmap": .framework,
            "Factory": .framework,
            "OpenAI": .framework,
            "PostHog": .framework,
            "RevenueCat": .framework,
            "RevenueCatUI": .framework
        ],
        baseSettings: .settings(base: iOSDeploymentTarget),
        targetSettings: [
            "DesignKit": iOSDeploymentTarget,
            "Factory": iOSDeploymentTarget,
            "Gate": iOSDeploymentTarget,
            "HTTPTypes": iOSDeploymentTarget,
            "OpenAI": iOSDeploymentTarget,
            "OpenAPIRuntime": iOSDeploymentTarget,
            "phlibwebp": iOSDeploymentTarget,
            "PHPLCrashReporter": iOSDeploymentTarget,
            "PostHogObjCExceptionSupport": iOSDeploymentTarget,
            "PostHog": iOSDeploymentTarget,
            "RevenueCat": iOSDeploymentTarget,
            "RevenueCatUI": iOSDeploymentTarget,
            "Roadmap": iOSDeploymentTarget,
            "Telemetry": iOSDeploymentTarget
        ]
    )
#endif

let package = Package(
    name: "Fig",
    dependencies: [
        .package(url: "https://github.com/mayankgandhi/Gate", exact: "1.0.0"),

        .package(url: "https://github.com/mayankgandhi/Telemetry", exact: "1.0.0"),

        .package(url: "https://github.com/mayankgandhi/DesignKit", exact: "1.0.2"),

        .package(url: "https://github.com/AvdLee/Roadmap", exact: "1.1.0"),

        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.0"),

        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0"),

        // RevenueCat, pulled in transitively by Gate. Pinned forward explicitly because
        // 5.47.1 does not compile under Swift 6.2 (Xcode 27): PaywallColor.swift hits
        // "invalid redeclaration of synthesized memberwise init".
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.102.0"),

    ]
)
