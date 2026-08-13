# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An error on a stored property whose type expands a parameter pack, such as `let values: (repeat each T)`. A copy is built by passing each property to an initializer, and Swift does not compile such a call for a value that expands a pack — with a memberwise initializer or one written by hand alike — so a type that stores one needs a `copying` written by hand. Types generic over a pack are otherwise copied as usual.
- An error on a stored property declared inside `#if`. A macro is handed the declaration before the directives are resolved, so such a property was invisible and the generated call simply left it out: on the configurations where its branch is active the expansion failed to compile, or — when the initializer defaults that parameter — silently reset the property on every copy. Every clause is checked, `#elseif`, `#else`, and nested directives included. A member inside `#if` that a copy never carries anyway, such as a computed, `static`, or `lazy` property or a `let` with an initial value, is still skipped silently.
- A warning on a `class` that is not `final`, with a Fix-It that marks it. `copying` builds the copy by calling the annotated type's own initializer and returns it as that type, so a subclass inherited a method that rebuilt only the superclass: its own stored properties were dropped and the dynamic type changed, with nothing in the language to catch it. The Fix-It writes `final` after any modifier the class already carries and demotes an `open` class to `public final`, since `open` and `final` contradict each other. A `struct` and an `actor` cannot be subclassed and are never flagged. It is a warning rather than an error because a class nothing subclasses copies itself correctly.

### Changed

- The generated `copying` method now caps its access level at the least visible property it copies, the rule Swift applies to a struct's memberwise initializer. It previously took the annotated type's level alone, so a `public` type with an `internal` or `private` property got a `public` method — which either handed out what the property's access level withholds, letting any module build a copy that varies it, or did not compile at all, because a `public` method cannot take a parameter of a less visible type. The type's own level counts as before: `open` yields `public`, and a `private` type yields `fileprivate`. A `private` property is the one reversal — it keeps the method `private`, which reaches the type declaration and its extensions in the same file, exactly as far as the property does. A modifier that constrains only the setter, such as `private(set)`, does not lower the cap, since `copying` reads the property rather than assigning through it, and neither do the members the method does not copy. The initializer the Fix-It writes carries the same capped level, and a type declared `internal` explicitly now yields a method with no modifier spelled out — the same level, written the way a declaration carries it by default. To keep a `public` copying method, declare the copied properties `public`.

### Fixed

- Spell a parameter pack in the generated return type as an expansion. A type such as `struct Bundle<each T>` produced `-> Bundle<T>`, which Swift rejects with "pack reference 'T' can only appear in pack expansion", so the expansion never compiled; the return type now reads `Bundle<repeat each T>`. A plain generic parameter, constrained or not, keeps its bare name as before.
- No more false "missing initializer" warning when the initializer is declared inside `#if`. The initializer was invisible for the same reason a conditional property was, so the macro reported one as missing and offered a Fix-It that wrote a second initializer with the signature the first one already had. Any conditionally compiled initializer now silences the check, since a macro cannot know which branch a build takes.
- Spell the `copying` parameter of an implicitly unwrapped optional property, such as `var label: UILabel!`, as a plain optional. Swift only accepts `!` at the top level of a property's or a parameter's type, so the `(UILabel!)?` parameter generated before did not compile. It denotes the same type as `(UILabel?)?`, so the parameter takes the same arguments and the property stays implicitly unwrapped in the copy. The initializer the Fix-It writes is a top-level position and keeps the declared `UILabel!`.
- Accept bindings that share one type annotation, such as `var x, y: Int`. Swift attaches the annotation to the last binding only, so every preceding one was reported as missing a type and the expansion failed on code that compiles. A binding now takes the annotation of a later binding in the same declaration, stopping at the first one with an initial value — which types itself by inference, and which Swift rejects sharing an annotation with anyway (`var x, y: Int = 0`).

## [1.4.0] - 2026-07-17

### Added

- The rendered API documentation is now published to GitHub Pages at <https://yysskk.github.io/swift-copying/documentation/copying>, built from the DocC catalog on every push to `main`.
- A warning that names the initializer `copying` needs, such as `init(id:username:isActive:)`, when the annotated declaration does not appear to declare one. Forgetting it previously surfaced only as an argument-label error inside the generated code, which did not say what was wrong. A `class` or `actor` is always checked, and so is a `struct` that suppresses its memberwise initializer by declaring an initializer of its own. It is a warning rather than an error because an initializer added in an extension or inherited from a superclass also satisfies the call but is invisible to a macro.
- A warning on an initializer that takes the copied properties but is `init?`, throwing, or `async`, since `copying` calls it as a plain expression. This too previously surfaced only inside the generated code, as an unwrapping, `try`, or `await` error. An `init!` is accepted: its result unwraps implicitly, so the call compiles.
- A Fix-It on the warning above that writes the missing initializer into the declaration, assigning each copied property and matching the access level of the generated method. It is offered only when no initializer is visible: an initializer that takes the right arguments but is `init?` or throwing has to be changed rather than joined by another, since Swift rejects a plain overload of one as a redeclaration.

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

[Unreleased]: https://github.com/yysskk/swift-copying/compare/1.4.0...HEAD
[1.4.0]: https://github.com/yysskk/swift-copying/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/yysskk/swift-copying/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/yysskk/swift-copying/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/yysskk/swift-copying/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/yysskk/swift-copying/releases/tag/1.0.0
