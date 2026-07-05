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

### Declarations that are rejected

The macro emits an error, so the mistake surfaces at compile time instead of corrupting copies:

- **A copyable property without a type annotation**, such as `var count = 0`. The macro sees only syntax and cannot infer the type, so annotate it: `var count: Int = 0`. (Left unchecked, the property would silently reset to its default on every copy.)
- **A `var` bound through a tuple pattern**, such as `var (x, y) = (0, 0)`. Declare each property on its own line so the macro can address them individually.
- **Applying `@Copying` to anything other than a `struct`, `class`, or `actor`.**

When several properties break the rules, every violation is reported in a single build.

### The initializer requirement

The generated method builds the copy by calling `TypeName(label: value, …)` using each copyable property's name as the argument label. A `struct` gets exactly this from its memberwise initializer for free. A `class` or `actor` must declare a matching initializer yourself — see <doc:GettingStarted>.
