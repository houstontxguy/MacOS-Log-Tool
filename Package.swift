// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacOSLogTool",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "logtool", targets: ["LogTool"]),
        .executable(name: "LogToolApp", targets: ["LogToolApp"]),
        .library(name: "LogToolCore", targets: ["LogToolCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
    ],
    targets: [
        .executableTarget(
            name: "LogTool",
            dependencies: [
                "LogToolCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "LogToolApp",
            dependencies: ["LogToolCore"]
        ),
        .target(
            name: "LogToolCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "LogToolCoreTests",
            dependencies: ["LogToolCore"],
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
