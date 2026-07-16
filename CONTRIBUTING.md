# Contributing

Thanks for your interest in improving swift-copying! This guide covers how to set up the project, the conventions the codebase follows, and what a change is expected to include.

## Development setup

You need a Swift 6.2 or later toolchain (the CI also builds on Swift 6.3).

```sh
git clone https://github.com/yysskk/swift-copying.git
cd swift-copying

swift build   # build the package
swift test    # run the test suite
```

## Project layout

- `Sources/Copying` — the public `@Copying` macro declaration and the DocC catalog.
- `Sources/CopyingMacros` — the macro implementation, split by responsibility:
  - `Plugin.swift` — the compiler plugin entry point.
  - `CopyingMacro.swift` — the `MemberMacro` conformance: declaration dispatch and orchestration.
  - `StoredProperty.swift` — selecting the copyable stored properties and reporting problematic ones.
  - `CopyingMethodRenderer.swift` — rendering the generated `copying` method.
  - `CopyingDiagnostic.swift` — the diagnostics the macro emits.
- `Sources/CopyingClient` — a small executable that exercises the macro end to end.
- `Tests/CopyingMacrosTests` — macro **expansion** tests (assert the generated source and diagnostics).
- `Tests/CopyingTests` — **runtime** tests (assert that the generated code compiles and behaves correctly).

## Formatting

The project uses [swift-format](https://github.com/swiftlang/swift-format) with the settings in [`.swift-format`](.swift-format). CI fails if the code is not formatted, so format before pushing:

```sh
swift format --in-place --recursive Sources Tests Package.swift
```

You can check without modifying files the same way CI does:

```sh
swift format lint --strict --recursive Sources Tests Package.swift
```

## Tests

Every behavior change should be covered by both kinds of test:

- An **expansion test** in `Tests/CopyingMacrosTests` asserting the exact generated code (or the emitted diagnostic, with its message and source location).
- A **runtime test** in `Tests/CopyingTests` asserting that the generated code compiles and produces the expected result.

Run the full suite with `swift test` before opening a pull request.

## swift-syntax compatibility

The macro implementation is built on swift-syntax, and `Package.swift` depends on a
deliberately wide version range so swift-copying resolves alongside other macro
packages regardless of which swift-syntax major they pin.

To check the package against a swift-syntax version the range does not cover yet —
typically a prerelease of the next major — set `SWIFT_COPYING_SWIFT_SYNTAX_VERSION`
to an exact version. It overrides the range with that single version:

```sh
SWIFT_COPYING_SWIFT_SYNTAX_VERSION=605.0.0-prerelease-2026-06-26 swift test
```

CI runs this on every pull request against the next major's prerelease, so breaking
changes surface before the range is widened. That job reports early warning only and
is not part of the required `test` check: swift-copying does not claim support for an
unreleased swift-syntax, so a failure there must never block an unrelated change.

Leave the variable unset for normal development; it is only a testing aid, and the
range in `Package.swift` is what consumers resolve against.

## Documentation

The public API is documented with symbol comments, and the articles under
`Sources/Copying/Copying.docc` cover the rules, optional-property semantics, and a
getting-started guide. On every push to `main`, the `Documentation` workflow builds
the catalog and publishes it to GitHub Pages.

Documentation is built with the [Swift-DocC plugin](https://github.com/swiftlang/swift-docc-plugin).
To keep it out of the dependency graph of packages that depend on swift-copying, the
plugin is only added when the `SWIFT_COPYING_BUILD_DOCS` environment variable is set.

Preview the documentation locally with a live-reloading server:

```sh
SWIFT_COPYING_BUILD_DOCS=1 swift package --disable-sandbox \
    preview-documentation --target Copying
```

Then open the printed URL (for example `http://localhost:8080/documentation/copying`).

## Commit and pull request conventions

- Branch off `main` with a prefix that matches the change: `feat/…`, `fix/…`, `refactor/…`, `chore/…`, `ci/…`, or `docs/…`.
- Write [Conventional Commits](https://www.conventionalcommits.org/): a lowercase, imperative subject prefixed with the type, e.g. `fix: exclude lazy properties from copying`.
- Keep each pull request focused on a single concern, and describe what changed and how you tested it.
- Make sure `swift build`, `swift test`, and `swift format lint --strict` all pass. CI runs the same checks on Linux and macOS, and they must be green before a pull request is merged.
