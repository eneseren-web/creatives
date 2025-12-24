// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImageDock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ImageDock", targets: ["ImageDockApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ImageDockApp",
            path: "Sources",
            resources: [
                .process("ImageDockApp/Resources")
            ]
        )
    ]
)
