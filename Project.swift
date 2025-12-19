import ProjectDescription

let project = Project(
    name: "SpoolOfRock",
    targets: [
        .target(
            name: "SpoolOfRock",
            destinations: .iOS,
            product: .app,
            bundleId: "com.spoolofrock.app",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["SpoolOfRock/Sources/**"],
            resources: ["SpoolOfRock/Resources/**"],
            entitlements: "SpoolOfRock/SpoolOfRock.entitlements",
            dependencies: []
        ),
        .target(
            name: "SpoolOfRockTests",
            destinations: .iOS,
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
