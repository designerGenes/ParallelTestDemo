import ProjectDescription

let project = Project(
    name: "Playground",
    organizationName: "DesignerGen",
    targets: [
        .target(
            name: "Playground",
            destinations: .iOS,
            product: .app,
            bundleId: "es.designergen.Playground",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: ["Playground/Sources/**"],
            dependencies: []
        ),
        .target(
            name: "PlaygroundUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "es.designergen.PlaygroundUITests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["PlaygroundUITests/Sources/**"],
            dependencies: [
                .target(name: "Playground")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Playground",
            shared: true,
            buildAction: .buildAction(targets: ["Playground"]),
            testAction: .targets(
                [.testableTarget(target: .target("PlaygroundUITests"))],
                configuration: .debug,
                options: .options(coverage: false)
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: .target("Playground")
            )
        )
    ]
)
