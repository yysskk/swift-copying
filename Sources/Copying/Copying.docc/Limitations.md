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
