// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "PostHog": .framework,
            "Roadmap": .framework,
            "RevenueCat": .framework,
            "RevenueCatUI": .framework
        ]
    )
#endif

let package = Package(
    name: "Fig",
    dependencies: [
        // Analytics - Shared
        .package(url: "https://github.com/PostHog/posthog-ios", exact: "3.31.0"),

        // UI Components
        .package(url: "https://github.com/AvdLee/Roadmap", exact: "1.1.0"),

        // Subscriptions
        .package(url: "https://github.com/RevenueCat/purchases-ios", exact: "5.15.0")
    ]
)
