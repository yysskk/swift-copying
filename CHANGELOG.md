# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-07-04

### Added

- A DocC documentation catalog and Swift Package Index metadata (`.spi.yml`), so the API reference and articles are hosted on the Swift Package Index.
- visionOS to the list of supported platforms.

### Changed

- The generated `copying` method now inherits the annotated type's access level instead of always being `public`. An `open` type produces a `public` method and a `private` type produces a `fileprivate` one, so the method is callable exactly where the type is.
- Declarations that would previously have produced broken or silently incorrect copies are now reported as compile-time diagnostics: a copyable stored property without an explicit type annotation, and a `var` bound through a tuple pattern. Every offending property is reported in a single build.
- Widened the swift-syntax dependency range to `600.0.0 ..< 605.0.0` so the package resolves alongside other macro packages.

### Fixed

- Include every property in a combined declaration such as `let x: Int, y: Int`.
- Wrap generated parameter types in parentheses so function-typed and other compound-typed properties compile.
- Exclude `let` constants with an initial value and `lazy` properties from copying; including them previously failed to compile.

## [1.2.0] - 2026-01-28

### Added

- Support for `actor` types.

### Fixed

- Corrected the indentation of the generated `copying` method.

## [1.1.0] - 2026-01-22

### Added

- Support for generic types.

## [1.0.0] - 2026-01-21

### Added

- Initial release: the `@Copying` macro, which generates a `copying` method for `struct` and `class` types.

[Unreleased]: https://github.com/yysskk/swift-copying/compare/1.3.0...HEAD
[1.3.0]: https://github.com/yysskk/swift-copying/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/yysskk/swift-copying/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/yysskk/swift-copying/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/yysskk/swift-copying/releases/tag/1.0.0
