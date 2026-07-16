// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let swiftSyntaxURL = "https://github.com/swiftlang/swift-syntax.git"

// A wide range so this package resolves alongside other macro packages
// regardless of which stable swift-syntax major they pin.
let swiftSyntaxVersions: Range<Version> = "600.0.0"..<"605.0.0"

// Setting SWIFT_COPYING_SWIFT_SYNTAX_VERSION pins swift-syntax to one exact version
// instead of `swiftSyntaxVersions`, including a version the range does not cover such
// as a prerelease of the next major. CI uses this to catch breaking changes in an
// upcoming release before the range is widened to include it, so widening stays a
// one-line change. It is never set when the package is consumed as a dependency
// (see CONTRIBUTING.md).
let swiftSyntaxDependency: Package.Dependency = {
    guard let requested = Context.environment["SWIFT_COPYING_SWIFT_SYNTAX_VERSION"] else {
        return .package(url: swiftSyntaxURL, swiftSyntaxVersions)
    }
    // Fail loudly rather than falling back to the range, which would let a typo
    // silently report a pass for a version that was never built.
    guard let version = Version(requested) else {
        fatalError("SWIFT_COPYING_SWIFT_SYNTAX_VERSION is not a valid version: '\(requested)'")
    }
    return .package(url: swiftSyntaxURL, exact: version)
}()

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
    dependencies: [swiftSyntaxDependency],
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
