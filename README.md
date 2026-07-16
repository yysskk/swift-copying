# swift-copying

[![CI](https://github.com/yysskk/swift-copying/actions/workflows/test.yml/badge.svg)](https://github.com/yysskk/swift-copying/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/documentation-DocC-blue)](https://yysskk.github.io/swift-copying/documentation/copying)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyysskk%2Fswift-copying%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/yysskk/swift-copying)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyysskk%2Fswift-copying%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/yysskk/swift-copying)
[![License](https://img.shields.io/github/license/yysskk/swift-copying)](LICENSE)

A Swift macro that generates a `copying` method for `struct`, `class`, and `actor` types, similar to Kotlin's `copy` function for data classes.

`@Copying` adds a `copying` method that takes one optional argument per stored property and returns a new instance with the properties you pass replaced and the rest carried over from the original.

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yysskk/swift-copying.git", from: "1.2.0")
]
```

Then add `Copying` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Copying"]
)
```

### Xcode

1. Choose **File → Add Package Dependencies…**
2. Enter the package URL `https://github.com/yysskk/swift-copying.git`
3. Pick a dependency rule, then add the **Copying** library product to your target.

## Usage

```swift
import Copying
```

### Structs

```swift
@Copying
struct Person {
    let name: String
    let age: Int
    let email: String
}

let john = Person(name: "John", age: 30, email: "john@example.com")

// Change one property
let olderJohn = john.copying(age: 31)
// Person(name: "John", age: 31, email: "john@example.com")

// Change several at once
let jane = john.copying(name: "Jane", age: 25)
// Person(name: "Jane", age: 25, email: "john@example.com")
```

### Classes

A `class` must declare an initializer shaped like a struct's memberwise initializer — one argument per copyable stored property, labelled with the property's name — because the generated method calls it:

```swift
@Copying
final class User {
    let id: Int
    var username: String
    var isActive: Bool

    init(id: Int, username: String, isActive: Bool) {
        self.id = id
        self.username = username
        self.isActive = isActive
    }
}

let user = User(id: 1, username: "johndoe", isActive: true)
let inactiveUser = user.copying(isActive: false)
```

Leave the initializer out and the macro tells you exactly which one to add, with a Fix-It that inserts it, instead of letting the mistake surface as an error inside the generated code:

```
⚠️ @Copying requires 'User' to declare 'init(id:username:isActive:)',
   which the generated 'copying' method calls
   Fix-It: Add 'init(id:username:isActive:)'
```

### Actors

Actors work the same way. Because `copying` is actor-isolated, call it with `await` from outside the actor:

```swift
@Copying
actor Counter {
    let id: Int
    var value: Int

    init(id: Int, value: Int) {
        self.id = id
        self.value = value
    }
}

let counter = Counter(id: 1, value: 0)
let advanced = await counter.copying(value: 10)
```

### Optional properties

Every parameter defaults to `nil`, meaning "keep the current value". For an optional property, the parameter becomes a double optional so you can still reset it:

```swift
@Copying
struct Config {
    let name: String
    let timeout: Int?
}

let config = Config(name: "default", timeout: 30)

config.copying(timeout: nil)         // keeps 30 — the nil literal means "no change"
config.copying(timeout: .some(nil))  // resets to nil

let newTimeout: Int? = nil
config.copying(timeout: newTimeout)  // also resets to nil
```

Because the bare `nil` literal keeps the current value, reset an optional with `.some(nil)` or by passing a value of the property's own optional type.

## How it works

`@Copying` is an attached member macro. Applying it to:

```swift
@Copying
struct Person {
    let name: String
    let age: Int
}
```

generates the following method inside `Person`:

```swift
func copying(
    name: (String)? = nil,
    age: (Int)? = nil
) -> Person {
    Person(
        name: name ?? self.name,
        age: age ?? self.age
    )
}
```

## What gets copied

The macro generates a parameter only for stored properties that can take part in a copy.

`weak` and `unowned` references are copied like any other stored property and keep their specifier. So are property wrappers that provide `init(wrappedValue:)` — such as `@Published` and `@AppStorage` — because Swift's memberwise initializer then takes the wrapped type, which is what the generated call passes. `@Copying` composes with the `@Observable` macro too. A wrapper with *no* `init(wrappedValue:)` is the one unsupported shape; see [Limitations](https://yysskk.github.io/swift-copying/documentation/copying/limitations) for why it cannot be diagnosed and how to work around it.

**Skipped silently:**

- `static` (and `class`) type properties
- Computed properties (`willSet`/`didSet`-only properties are still stored and are included)
- `lazy` properties
- `let` constants with an initial value, e.g. `let maxValue: Int = 100`
- Immutable tuple bindings, e.g. `let (x, y) = (0, 0)`

**Rejected with a compile-time error:**

- A copyable property without an explicit type annotation, e.g. `var count = 0` (a macro cannot infer the type — write `var count: Int = 0`)
- A `var` bound through a tuple pattern, e.g. `var (x, y) = (0, 0)`
- A type with no copyable stored properties
- Applying `@Copying` to anything other than a `struct`, `class`, or `actor`

**Warned about, with the method still generated:**

- A `class` or `actor` (or a `struct` that declares its own initializer) with no initializer matching the generated call. The warning names the signature and offers a Fix-It that writes it.
- An initializer that takes the copied properties but is `init?`, throwing, or `async`, none of which `copying` can call as a plain expression. (`init!` is fine — its result unwraps implicitly.)

These are warnings rather than errors because an initializer declared in an extension or inherited from a superclass satisfies the call but is invisible to a macro, which only sees the declaration it is attached to.

The generated method inherits the type's access level: an `open` type produces a `public` method, and a `private` type produces a `fileprivate` one, so the method is callable exactly where the type is.

## Documentation

Full API documentation, including articles on the rules, optional-property semantics, and a getting-started guide, is published to [GitHub Pages](https://yysskk.github.io/swift-copying/documentation/copying). It is also available on the [Swift Package Index](https://swiftpackageindex.com/yysskk/swift-copying/documentation/copying).

## Requirements

- Swift 6.2+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+ / visionOS 1+ / Mac Catalyst 13+

## License

swift-copying is available under the MIT license. See [LICENSE](LICENSE) for details.
