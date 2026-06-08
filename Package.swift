// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSourceProtection",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "SwiftSourceProtection", targets: [
            "SwiftSourceProtection"
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Csourcekitd",
            dependencies: []
        ),
        .executableTarget(
            name: "SwiftSourceProtection",
            dependencies: [
                "Csourcekitd",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ], swiftSettings: [
                .swiftLanguageMode(.v5),
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"])
            ]
        ),
    ]
)
