// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PurrBreak",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PurrBreak", targets: ["PurrBreak"])
    ],
    targets: [
        .executableTarget(
            name: "PurrBreak",
            path: "Sources/PurrBreak",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
