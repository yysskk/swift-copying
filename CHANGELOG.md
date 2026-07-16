# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The rendered API documentation is now published to GitHub Pages at <https://yysskk.github.io/swift-copying/documentation/copying>, built from the DocC catalog on every push to `main`.
- A warning that names the initializer `copying` needs, such as `init(id:username:isActive:)`, when the annotated declaration does not appear to declare one. Forgetting it previously surfaced only as an argument-label error inside the generated code, which did not say what was wrong. A `class` or `actor` is always checked, and so is a `struct` that suppresses its memberwise initializer by declaring an initializer of its own. It is a warning rather than an error because an initializer added in an extension or inherited from a superclass also satisfies the call but is invisible to a macro.
- A warning on an initializer that takes the copied properties but is `init?`, throwing, or `async`, since `copying` calls it as a plain expression. This too previously surfaced only inside the generated code, as an unwrapping, `try`, or `await` error. An `init!` is accepted: its result unwraps implicitly, so the call compiles.

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
