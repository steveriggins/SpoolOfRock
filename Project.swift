import ProjectDescription

let project = Project(
    name: "SpoolOfRock",
    targets: [
        .target(
            name: "SpoolOfRock",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.spoolofrock.app",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "NFCReaderUsageDescription": "SpoolOfRock uses NFC to identify and track your filament spools",
                    "UIBackgroundModes": ["remote-notification"]
                ]
            ),
            sources: ["SpoolOfRock/Sources/**"],
            resources: ["SpoolOfRock/Resources/**"],
            entitlements: "SpoolOfRock/SpoolOfRock.entitlements",
            dependencies: [],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "[TEAM_ID]",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
                ]
            )
        ),
        .target(
            name: "SpoolOfRockTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "com.spoolofrock.app.tests",
            infoPlist: .default,
            sources: ["SpoolOfRock/Tests/**"],
            dependencies: [
                .target(name: "SpoolOfRock")
            ]
        )
    ]
)
