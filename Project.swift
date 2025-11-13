import ProjectDescription

// Centralized app configuration
let appName = "Ticker"
let productName = "Ticker"
let version = "1.1"
let buildNumber = "1"
let mainBundleId = "m.fig"
let widgetsBundleId = "\(mainBundleId).widgets"
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
                "Ticker/Sources/**/**",
                "Ticker/Sources/*"
            ],
            resources: [
                "Ticker/Resources/**/**",
                "Ticker/Resources/*"
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": .array([.string("group.m.fig")]),
                "com.apple.developer.siri": .boolean(true),
            ]),
            dependencies: [
                .project(target: "TickerWidgets", path: "TickerWidgets"),
                .project(target: "TickerCore", path: "TickerCore"),
                .external(name: "Gate"),
                .external(name: "Telemetry"),
                .external(name: "DesignKit")
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget)
                ].automaticCodeSigning(devTeam: developmentTeam),
                configurations: []
            )
        ),
        // Unit test target
        .target(
            name: "TickerTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "\(mainBundleId).tests",
            infoPlist: .default,
            sources: [
                "Ticker/Tests/TickerTests/**"
            ],
            dependencies: [
                .target(name: appName)
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget)
                ],
                configurations: []
            )
        ),
        // UI test target
        .target(
            name: "TickerUITests",
            destinations: [.iPhone, .iPad],
            product: .uiTests,
            bundleId: "\(mainBundleId).uitests",
            infoPlist: .default,
            sources: [
                "Ticker/Tests/TickerUITests/**"
            ],
            dependencies: [
                .target(name: appName)
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget)
                ],
                configurations: []
            )
        ),
    ],
//    schemes: [
//        .scheme(
//            name: appName,
//            shared: true,
//            buildAction: .buildAction(targets: [.init(stringLiteral: appName)]),
//            testAction: .targets(
//                ["\(appName)Tests"],
//                configuration: .debug,
//                options: .options(coverage: true)
//            ),
//            runAction: .runAction(configuration: .debug),
//            archiveAction: .archiveAction(configuration: .release),
//            profileAction: .profileAction(configuration: .release),
//            analyzeAction: .analyzeAction(configuration: .debug)
//        )
//    ]
)
