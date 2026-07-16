# Limitations and Rules

Learn which stored properties `copying` includes and what the macro requires of your declarations.

## Overview

``Copying()`` generates a parameter only for the stored properties that can take part in a copy. It skips some declarations silently and rejects others with a compile-time error.

### Properties that are skipped

These properties are left out of `copying` without any diagnostic, because copying them makes no sense or is unnecessary:

- **Type properties** declared with `static` (or `class`), which are not part of an instance's state.
- **Computed properties**, whether written as a single expression, an explicit `get`, or a `get`/`set` pair. Properties that only observe changes with `willSet`/`didSet` are still stored and *are* included.
- **`lazy` properties.** Reading one inside `copying` would require a mutating getter on a `struct`, and a fresh copy recomputes the value on demand anyway.
- **`let` constants with an initial value**, such as `let maxValue: Int = 100`. Their value is fixed and the memberwise initializer excludes them.
- **Immutable tuple bindings**, such as `let (x, y) = (0, 0)` (allowed in a `class` or `actor`). They are constants, so there is nothing to vary. The mutable `var` form is rejected instead — see below.

### Declarations that are rejected

The macro emits an error, so the mistake surfaces at compile time instead of corrupting copies:

- **A copyable property without a type annotation**, such as `var count = 0`. The macro sees only syntax and cannot infer the type, so annotate it: `var count: Int = 0`. (Left unchecked, the property would silently reset to its default on every copy.)
- **A `var` bound through a tuple pattern**, such as `var (x, y) = (0, 0)`. Declare each property on its own line so the macro can address them individually.
- **A type with no copyable stored properties at all.** `@Copying` needs at least one property it can vary.
- **Applying `@Copying` to anything other than a `struct`, `class`, or `actor`.**

When several properties break the rules, every violation is reported in a single build.

### The initializer requirement

The generated method builds the copy by calling `TypeName(label: value, …)` using each copyable property's name as the argument label. A `struct` gets exactly this from its memberwise initializer for free. A `class` or `actor` must declare a matching initializer yourself — see <doc:GettingStarted>.

The macro checks for that initializer and warns when it cannot find one, naming the signature it needs and offering a Fix-It that writes it:

```swift
@Copying
final class User {
    let id: Int
    var username: String
    var isActive: Bool
}
// ⚠️ @Copying requires 'User' to declare 'init(id:username:isActive:)',
//    which the generated 'copying' method calls
//    Fix-It: Add 'init(id:username:isActive:)'
```

The check applies to every `class` and `actor`, and to a `struct` that declares an initializer of its own, since doing so suppresses the memberwise initializer. A `struct` without one is never flagged.

An initializer counts as long as the generated call reaches it, so it does not have to match the signature exactly. Extra parameters are fine when the call can leave them out:

```swift
@Copying
final class User {
    let id: Int
    var tags: [String]

    // Satisfies the call, which passes only `id:` and `tags:`.
    init(audit: Bool = false, id: Int, notes: String..., tags: [String]) { … }
}
```

Property types are not compared, only argument labels, so a typealias or a generic parameter never trips the check.

### Initializers the copy cannot call

`copying` calls the initializer as a plain expression and returns the result as the type itself, so the initializer cannot be failable (`init?`), throwing, or `async` — each would make the call produce something other than a ready-made instance. The macro warns on the initializer itself when it takes the copied properties but has one of those shapes:

```swift
@Copying
final class User {
    let id: Int

    init?(id: Int) { … }
    // ⚠️ @Copying calls 'init(id:)' to build the copy, so it cannot be
    //    failable ('init?'), throwing, or async
}
```

There is no Fix-It here, because that initializer has to change rather than be joined by another: Swift rejects a plain overload of a failable or throwing initializer as a redeclaration.

An `init!` is accepted. It is failable too, but its implicitly unwrapped result converts to the type itself, so the call compiles — a copy traps instead of returning `nil`.

### Why these are warnings

Every other rule above is an error, but the two about initializers are warnings, because a macro only ever sees the declaration it is attached to. An initializer added in an extension, or inherited from a superclass, satisfies the generated call while being invisible to the check:

```swift
@Copying
final class Widget {          // No initializer here …
    var id: Int = 0
    var title: String = ""
}

extension Widget {
    convenience init(id: Int, title: String) { … }   // … but one here
}
```

That code compiles and `copying` works, yet the macro cannot know it. As an error the diagnostic would reject working code with no way to opt out; as a warning it costs one false positive at worst. For the same reason `copying` is still generated when either warning fires.

### Property wrappers

A wrapped property is copied like any other: the macro reads the property's declared — that is, wrapped — type and ignores the attribute.

```swift
@Copying
final class ViewModel {
    @Published var title: String
    @Published var count: Int

    init(title: String, count: Int) { … }
}

let draft = ViewModel(title: "Draft", count: 1)
let copy = draft.copying(count: 2)   // title carried over, count replaced
```

This is correct whenever the wrapper provides `init(wrappedValue:)`, because Swift then gives the memberwise initializer a parameter of the *wrapped* type — exactly what the generated call passes. That covers `@Published`, `@AppStorage`, and most custom wrappers.

A wrapper configured by attribute arguments works too, as long as it still offers an `init(wrappedValue:…)`. Each copy is rebuilt through the initializer, so the wrapper runs again and its arguments are reapplied:

```swift
@Copying
struct Volume {
    @Clamped(range: 0...11) var level: Int = 5
}

Volume(level: 20).level                     // 11 — clamped on the way in
Volume(level: 20).copying(level: -3).level  // 0  — and clamped again on the copy
```

`@Copying` also composes with the `@Observable` macro, which leaves the declared property type reachable through `self`:

```swift
@Observable
@Copying
final class Settings {
    var theme: String
    var fontSize: Int

    init(theme: String, fontSize: Int) { … }
}
```

### Wrappers without `init(wrappedValue:)`

A wrapper that can only be built from its own arguments is the one shape that does not work:

```swift
@propertyWrapper
struct Boxed<Value> {
    var wrappedValue: Value
    init(value: Value) { self.wrappedValue = value }   // and no init(wrappedValue:)
}

@Copying
struct Model {
    @Boxed(value: 1) var count: Int
}
// ❌ error: cannot convert value of type 'Int' to expected argument type 'Boxed<Int>'
```

Without an `init(wrappedValue:)`, the memberwise initializer takes the *backing wrapper* (`Boxed<Int>`) rather than the wrapped value, while `copying` passes the wrapped value (`Int`), so the generated call does not type-check.

Unlike every rule above, this one is not diagnosed. A macro sees only syntax, and there the two shapes are identical: `@Clamped(range: 0...11)` and `@Boxed(value: 1)` are both attributes with arguments, and only the wrapper's own declaration — which a macro cannot resolve — says whether an `init(wrappedValue:)` exists. Warning on every wrapped property would mean warning about the far more common working case, so the macro stays quiet and lets the compiler report the mismatch.

To copy such a property anyway, declare an initializer that takes the wrapped value and builds the backing wrapper itself. It suppresses the memberwise initializer, and the generated call resolves to it:

```swift
@Copying
struct Model {
    @Boxed(value: 1) var count: Int

    init(count: Int) {
        self._count = Boxed(value: count)
    }
}
```

### Reference storage

`weak` and `unowned` are storage specifiers rather than exclusions, so a reference held either way is copied like any other stored property and keeps its specifier in the copy:

```swift
@Copying
final class Node {
    var name: String
    weak var next: Node?

    init(name: String, next: Node?) { … }
}
```

The copy holds `next` weakly too, so it does not keep the referent alive. A `weak` property is always optional, so its parameter is a double optional and follows <doc:OptionalProperties>: `copying(next: nil)` keeps the current reference, while `copying(next: .some(nil))` clears it.
