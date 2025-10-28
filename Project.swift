import ProjectDescription

// Centralized app configuration
let appName = "Ticker"
let productName = "Ticker"
let version = "1.0.0"
let buildNumber = "1"
let mainBundleId = "m.fig"
let alarmBundleId = "\(mainBundleId).alarm"
let developmentTeam = "Q7HVAVTGUP"
let deploymentTarget = "26.0"

let project = Project(
    name: appName,
    targets: [
        // Main app target
        .target(
            name: appName,
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: mainBundleId,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string(productName),
                "CFBundleShortVersionString": .string(version),
                "CFBundleVersion": .string(buildNumber),
                "UILaunchScreen": [:],
                "NSAlarmKitUsageDescription": "This app needs access to alarms to notify you when your timers expire.",
                "BGTaskSchedulerPermittedIdentifiers": .array([
                    .string("com.fig.alarm.regeneration")
                ])
            ]),
            sources: [
                "fig/**",
                "Shared/**"
            ],
            resources: [
                .glob(pattern: "fig/Resources/Assets.xcassets"),
                .glob(pattern: "fig/Resources/AppIcon.icon/**"),
                .glob(pattern: "fig/Resources/*.caf"),
                .glob(pattern: "fig/Resources/*.wav")
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": .array([.string("group.m.fig")]),
                "com.apple.developer.siri": .boolean(true),
            ]),
            dependencies: [
                .target(name: "alarm")
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget)
                ].automaticCodeSigning(devTeam: developmentTeam),
                configurations: []
            )
        ),

        // Widget extension target
        .target(
            name: "alarm",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: alarmBundleId,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Ticker"),
                "CFBundleShortVersionString": .string(version),
                "CFBundleVersion": .string(buildNumber),
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: [
                "alarm/**",
                "Shared/**",  // Includes Shared/Extensions, TickerDesignSystem, ClockView, Shared/AppIntents, Shared/Services, etc.
                "fig/DesignSystem/**",  // Design system previews
                "fig/Models/ActivityIconMapper.swift",  // Activity icon mapper for ticker data
                "fig/Models/IconColorPair.swift"  // Icon color pair for ticker data
            ],
            resources: [
                "alarm/Assets.xcassets",
                .glob(pattern: "fig/Resources/*.caf"),
                .glob(pattern: "fig/Resources/*.wav")
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": .array([.string("group.m.fig")])
            ]),
            dependencies: [],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget),
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES"
                ].automaticCodeSigning(devTeam: developmentTeam),
                configurations: []
            )
        ),

        // Unit tests
        .target(
            name: "\(appName)Tests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.mayankgandhi.figTests",
            sources: ["figTests/**"],
            dependencies: [
                .target(name: appName)
            ]
        ),

        // UI tests
        .target(
            name: "\(appName)UITests",
            destinations: [.iPhone, .iPad, .mac],
            product: .uiTests,
            bundleId: "com.mayankgandhi.figUITests",
            sources: ["figUITests/**"],
            dependencies: [
                .target(name: appName)
            ]
        )
    ]
)
