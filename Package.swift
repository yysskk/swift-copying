// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-copying",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1), .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Copying",
            targets: ["Copying"]
        ),
    ],
    dependencies: [
        // A wide range so this package resolves alongside other macro packages
        // regardless of which stable swift-syntax major they pin.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
    ],
    targets: [
        .macro(
            name: "CopyingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .target(name: "Copying", dependencies: ["CopyingMacros"]),
        .executableTarget(name: "CopyingClient", dependencies: ["Copying"]),
        .testTarget(
            name: "CopyingMacrosTests",
            dependencies: [
                "CopyingMacros",
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "CopyingTests",
            dependencies: ["Copying"]
        ),
    ]
)
