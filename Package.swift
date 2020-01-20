// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "mbox",
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("master")),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "mbox",
            dependencies: ["SwiftToolsSupport-auto", "Files"]),
        .testTarget(
            name: "mboxTests",
            dependencies: ["mbox"]),
    ]
)
