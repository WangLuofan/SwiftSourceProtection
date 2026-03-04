// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSourceProtection",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "SwiftSourceProtection", targets: [
            "SwiftSourceProtection"
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.34.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SwiftSourceProtection",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
            ], swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-swift-version", "5.5"]),
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-availability-checking",
                ]),
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=off"])
            ]
        ),
    ]
)
