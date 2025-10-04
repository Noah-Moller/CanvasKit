// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CanvasKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CanvasKit",
            targets: ["CanvasKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CanvasKit",
            dependencies: [],
            path: "Sources/CanvasKit"
        ),
        .testTarget(
            name: "CanvasKitTests",
            dependencies: ["CanvasKit"],
            path: "Tests/CanvasKitTests"
        ),
    ]
)
