// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-copying",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "Copying",
            targets: ["Copying"]
        ),
        .executable(
            name: "CopyingClient",
            targets: ["CopyingClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .macro(
            name: "CopyingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "Copying", dependencies: ["CopyingMacros"]),
        .executableTarget(name: "CopyingClient", dependencies: ["Copying"]),
        .testTarget(
            name: "CopyingTests",
            dependencies: [
                "CopyingMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
