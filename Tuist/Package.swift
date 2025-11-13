// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "Gate": .framework,
            "Telemetry": .framework,
            "DesignKit": .framework
        ]
    )
#endif

let package = Package(
    name: "Fig",
    dependencies: [
        .package(url: "https://github.com/mayankgandhi/Gate", branch: "main"),
        .package(url: "https://github.com/mayankgandhi/Telemetry", branch: "main"),
        .package(url: "https://github.com/mayankgandhi/DesignKit", branch: "main")
    ]
)
