// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VIN",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        //.linux
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "VIN",
            targets: ["VIN"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "VIN",
            dependencies: []
        ),
        .testTarget(
            name: "VINTests",
            dependencies: ["VIN"]
        ),
    ]
)
