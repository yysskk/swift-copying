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
  - `InitializerRequirement.swift` — the initializer the generated method calls, and whether the declaration offers one.
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

The macro implementation is built on swift-syntax, and `Package.swift` declares the
supported releases as a deliberately wide range:

```swift
.package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
```

Nothing in swift-copying needs that many majors. The width is for consumers. SwiftPM
resolves a single swift-syntax version for the whole dependency graph, so when someone
depends on swift-copying *and* on another macro package, the two ranges have to overlap
or the graph does not resolve at all. That failure cannot be worked around downstream —
it is not a warning a consumer can defer — which makes keeping this range as wide as is
honest the most valuable compatibility work in the repository.

Both bounds carry weight:

- **The floor stays at `600.0.0`.** Raising it strands consumers pinned to an older
  major. The `Linux (Swift 6.2, swift-syntax 600.0.0)` job builds against the floor so
  it cannot rot unnoticed.
- **The ceiling is exclusive, and moves only to a major that has a stable release.** A
  prerelease is not a release: its API can still change, so the range must never promise
  support for one.

### Testing against an unreleased version

To check the package against a swift-syntax version the range does not cover yet —
typically a prerelease of the next major — set `SWIFT_COPYING_SWIFT_SYNTAX_VERSION` to
an exact version. It replaces the range with that single version:

```sh
swift package clean   # only needed when switching versions
SWIFT_COPYING_SWIFT_SYNTAX_VERSION=605.0.0-prerelease-2026-06-26 swift test
```

Clean first when you have already built against a different swift-syntax: the macro
links against it, and object files from one version do not relink against another. The
failure is a confusing `Undefined symbols` link error rather than anything that names
the real cause.

CI runs this on every pull request against the next major's prerelease, so breaking
changes surface before the range is widened. That job reports early warning only and is
not part of the required `test` check: swift-copying does not claim support for an
unreleased swift-syntax, so a failure there must never block an unrelated change.

Leave the variable unset for normal development; it is only a testing aid, and the range
in `Package.swift` is what consumers resolve against.

### Following a new swift-syntax major

Because the ceiling is exclusive, `..<"605.0.0"` supports every `604.x` release but no
`605.x` one. A new major reaches consumers only when that bound moves.

Dependabot proposes that move on its own. Its Swift updater rewrites the upper bound of
a range requirement to the major after the new version and leaves the lower bound alone,
so once `605.0.0` is released it should open a pull request taking
`"600.0.0"..<"605.0.0"` to `"600.0.0"..<"606.0.0"` — the intended result, floor
included. It can only do that while the declaration stays literal, which is why
`Package.swift` keeps it that way and applies the override separately.

Whether that pull request arrives on its own or has to be written by hand, check it the
same way:

1. The new major has a **stable** release. Dependabot ignores prereleases, so a proposal
   to widen for one should not appear — and should not be merged if it does.
2. The prerelease job has been green, so the API is already known to work. Confirm
   against the released version: `SWIFT_COPYING_SWIFT_SYNTAX_VERSION=605.0.0 swift test`.
3. The floor is untouched at `600.0.0`, and the floor job still passes.
4. Repoint the prerelease job in `.github/workflows/test.yml` at the next major's
   prerelease, or drop the job while no newer major exists.
5. Note the widened range in `CHANGELOG.md` under `Unreleased`.

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
