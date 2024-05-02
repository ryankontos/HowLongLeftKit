// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "How Long Left Kit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "How Long Left Kit",
            targets: ["How Long Left Kit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "How Long Left Kit"),
        .testTarget(
            name: "How Long Left KitTests",
            dependencies: ["How Long Left Kit"]),
    ]
)
