import ProjectDescription

let project = Project(
    name: "ProjectA",
    organizationName: "tuist.io",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.app",
            deploymentTarget: .iOS(targetVersion: "13.0", devices: .iphone),
            infoPlist: .default,
            sources: ["Targets/App/Sources/**"]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.AppTests",
            infoPlist: .default,
            sources: ["Targets/App/Tests/**"],
            dependencies: [
                .target(name: "App"),
            ]
        ),
    ]
)
