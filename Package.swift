// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-copying",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1), .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Copying",
            targets: ["Copying"]
        )
    ],
    dependencies: [
        // A wide range so this package resolves alongside other macro packages
        // regardless of which stable swift-syntax major they pin.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
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

// The Swift-DocC plugin is only needed to build the documentation, so it is added
// behind an environment flag. This keeps it out of the dependency graph of packages
// that depend on swift-copying, which never need to resolve it. Set
// SWIFT_COPYING_BUILD_DOCS when generating documentation (see CONTRIBUTING.md).
if Context.environment["SWIFT_COPYING_BUILD_DOCS"] != nil {
    package.dependencies.append(
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
    )
}
