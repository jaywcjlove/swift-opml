// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OPML",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OPML",
            targets: ["OPML"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OPML"
        ),
        .testTarget(
            name: "OPMLTests",
            dependencies: ["OPML"],
            resources: [
                .copy("Resources/rsparser.opml"),
                .copy("Resources/feedly.opml")
            ]
        ),
    ]
)
