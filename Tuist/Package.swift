// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "Gate": .framework,
            "Telemetry": .framework,
            "DesignKit": .framework,
            "Roadmap": .framework,
            "Factory": .framework
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

    ]
)
