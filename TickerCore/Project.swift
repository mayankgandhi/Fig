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
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Factory")
            ],
            settings: .settings(
                base: [
                    // Tuist's `swiftVersion: "6.0"` selects the toolchain, not the
                    // language mode — every target still compiles as SWIFT_VERSION
                    // 5.0. Turning strict concurrency on here surfaces the actor
                    // isolation problems in the alarm pipeline as diagnostics
                    // instead of as silent data races.
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ],
                configurations: []
            )
        ),

        // Test target
        .target(
            name: "TickerCoreTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "m.fig.tickercore.tests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "TickerCore"),
            ]
        )
    ],
)
