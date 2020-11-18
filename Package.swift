// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "mbox",

    platforms: [
        .macOS(.v10_10)
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.0.1"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.0.0"),
    ],

    targets: [
        .target(
            name: "mbox",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto",
                         package: "swift-tools-support-core"),
                "Files"]),
        .testTarget(
            name: "mboxTests",
            dependencies: ["mbox"]),
    ]
)
