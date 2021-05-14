// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "mbox",

    platforms: [
        .macOS(.v10_10)
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.0.0"),
    ],
    targets: [

        .target(
            name: "mbox",
            dependencies: [
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser"),
                "Files"]),
        .testTarget(
            name: "mboxTests",
            dependencies: ["mbox"]),
    ]
)
