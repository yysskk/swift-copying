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

## Commit and pull request conventions

- Branch off `main` with a prefix that matches the change: `feat/…`, `fix/…`, `refactor/…`, `chore/…`, `ci/…`, or `docs/…`.
- Write [Conventional Commits](https://www.conventionalcommits.org/): a lowercase, imperative subject prefixed with the type, e.g. `fix: exclude lazy properties from copying`.
- Keep each pull request focused on a single concern, and describe what changed and how you tested it.
- Make sure `swift build`, `swift test`, and `swift format lint --strict` all pass. CI runs the same checks on Linux and macOS, and they must be green before a pull request is merged.
