import ProjectDescription

// Configuration
let widgetsName = "TickerWidgets"
let version = "1.2"
let buildNumber = "1"
let widgetsBundleId = "m.fig.widgets"
let developmentTeam = "Q7HVAVTGUP"
let deploymentTarget = "26.0"

let project = Project(
    name: widgetsName,
    targets: [
        // Widget extension target
        .target(
            name: widgetsName,
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: widgetsBundleId,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Ticker"),
                "CFBundleShortVersionString": .string(version),
                "CFBundleVersion": .string(buildNumber),
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: [
                "Sources/**"
            ],
            resources: [
                "Sources/Assets.xcassets"
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": .array([.string("group.m.fig")])
            ]),
            dependencies: [
                .project(target: "TickerCore", path: "../TickerCore"),
                .external(name: "Gate"),
                .external(name: "Factory")
            ],
            settings: .settings(
                base: [
                    "IPHONEOS_DEPLOYMENT_TARGET": .string(deploymentTarget),
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES"
                ].automaticCodeSigning(devTeam: developmentTeam),
                configurations: []
            )
        )
    ]
)
