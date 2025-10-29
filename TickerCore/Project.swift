import ProjectDescription

let project = Project(
    name: "TickerCore",
    targets: [
        // Main framework target
        .target(
            name: "TickerCore",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "m.fig.tickercore",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Sources/TickerCore/**"],
            dependencies: []
        ),

        // Test target
        .target(
            name: "TickerCoreTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "m.fig.tickercore.tests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/TickerCoreTests/**"],
            dependencies: [
                .target(name: "TickerCore")
            ]
        )
    ]
)
