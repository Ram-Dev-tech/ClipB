// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipB",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipB", targets: ["ClipB"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.24.2"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.12.0")
    ],
    targets: [
        .executableTarget(
            name: "ClipB",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "ClipB",
            exclude: ["Info.plist", "ClipB.entitlements"],
            resources: [.process("Resources/Assets.xcassets")]
        )
    ]
)
