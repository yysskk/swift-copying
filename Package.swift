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
        //
        // Dependabot finds this dependency by matching a regular expression that
        // requires a literal URL and a literal requirement, so keep this declaration
        // literal and keep it the only one that can match. Assembling it from variables
        // makes Dependabot treat swift-syntax as an undeclared transitive dependency and
        // silently stop opening update pull requests for it, with no error anywhere.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
    ],
    targets: [
        .macro(
            name: "CopyingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
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

// Setting SWIFT_COPYING_SWIFT_SYNTAX_VERSION replaces the range above with the single
// version named, including one the range does not cover such as a prerelease of the next
// major. CI uses this to catch breaking changes in an upcoming release before the range
// is widened to include it. It is never set when the package is consumed as a dependency
// (see CONTRIBUTING.md).
if let requested = Context.environment["SWIFT_COPYING_SWIFT_SYNTAX_VERSION"] {
    // Fail loudly rather than falling back to the range, which would let a typo
    // silently report a pass for a version that was never built.
    guard let version = Version(requested) else {
        fatalError("SWIFT_COPYING_SWIFT_SYNTAX_VERSION is not a valid version: '\(requested)'")
    }
    // The URL goes through a variable so that Dependabot's regular expression matches
    // only the declaration above; were it a literal here too, Dependabot could read this
    // declaration instead and mistake `exact: version` for the supported requirement.
    // This runs before the DocC plugin is appended below, so only swift-syntax is
    // replaced.
    let swiftSyntaxURL = "https://github.com/swiftlang/swift-syntax.git"
    package.dependencies = [.package(url: swiftSyntaxURL, exact: version)]
}

// The Swift-DocC plugin is only needed to build the documentation, so it is added
// behind an environment flag. This keeps it out of the dependency graph of packages
// that depend on swift-copying, which never need to resolve it. Set
// SWIFT_COPYING_BUILD_DOCS when generating documentation (see CONTRIBUTING.md).
if Context.environment["SWIFT_COPYING_BUILD_DOCS"] != nil {
    package.dependencies.append(
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
    )
}
