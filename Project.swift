import ProjectDescription

let project = Project(
    name: "fig",
    targets: [
        // Main app target
        .target(
            name: "fig",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "m.fig",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "NSAlarmKitUsageDescription": "This app needs access to alarms to notify you when your timers expire."
            ]),
            sources: [
                "fig/**",
                "Shared/**"
            ],
            resources: [
                .glob(pattern: "fig/Resources/Assets.xcassets"),
                .glob(pattern: "fig/Resources/AppIcon.icon/**")
            ],
            dependencies: [
                .target(name: "alarm")
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": "26.0"
                ].automaticCodeSigning(devTeam: "Q7HVAVTGUP"),
                configurations: []
            )
        ),

        // Widget extension target
        .target(
            name: "alarm",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "m.fig.alarm",
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: [
                "alarm/**",
                "Shared/**",
                "fig/AppIntents/**"  // Share AppIntents with widget extension
            ],
            resources: ["alarm/Assets.xcassets"],
            dependencies: [],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": "26.0"
                ].automaticCodeSigning(devTeam: "Q7HVAVTGUP"),
                configurations: []
            )
        ),

        // Unit tests
        .target(
            name: "figTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.mayankgandhi.figTests",
            sources: ["figTests/**"],
            dependencies: [
                .target(name: "fig")
            ]
        ),

        // UI tests
        .target(
            name: "figUITests",
            destinations: [.iPhone, .iPad, .mac],
            product: .uiTests,
            bundleId: "com.mayankgandhi.figUITests",
            sources: ["figUITests/**"],
            dependencies: [
                .target(name: "fig")
            ]
        )
    ]
)
