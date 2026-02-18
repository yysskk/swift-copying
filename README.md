# swift-copying

A Swift Macro that generates a `copying` method for struct, class, and actor types, similar to Kotlin's `copy` function for data classes.

## Installation

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yysskk/swift-copying.git", from: "1.0.0")
]
```

Then add `Copying` to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Copying"]
)
```

## Usage

```swift
import Copying

@Copying
struct Person {
    let name: String
    let age: Int
    let email: String
}

let john = Person(name: "John", age: 30, email: "john@example.com")

// Copy with one property changed
let olderJohn = john.copying(age: 31)
// Person(name: "John", age: 31, email: "john@example.com")

// Copy with multiple properties changed
let jane = john.copying(name: "Jane", age: 25)
// Person(name: "Jane", age: 25, email: "john@example.com")

// Copy with all properties changed
let bob = john.copying(name: "Bob", age: 40, email: "bob@example.com")
// Person(name: "Bob", age: 40, email: "bob@example.com")
```

### Works with classes too

```swift
@Copying
class User {
    let id: Int
    let username: String
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

### Works with actors

```swift
@Copying
actor Counter {
    let id: Int
    let value: Int

    init(id: Int, value: Int) {
        self.id = id
        self.value = value
    }
}

let counter = Counter(id: 1, value: 0)
let updated = await counter.copying(value: 10)
```

### Works with generics

```swift
@Copying
struct Box<T> {
    let value: T
}

let intBox = Box(value: 42)
let stringBox = intBox.copying(value: "hello") // Box<String> — type changes with the value

@Copying
struct Pair<K, V> {
    let key: K
    let value: V
}

let pair = Pair(key: "name", value: 123)
let updated = pair.copying(value: 456)
```

### Optional properties

For optional properties, the parameter type becomes a double optional (`T??`) to distinguish between "keep current value" and "set to nil":

```swift
@Copying
struct Config {
    let name: String
    let value: Int?
}

let config = Config(name: "test", value: 42)

// Passing nil (or omitting) keeps the current value
let same = config.copying(value: nil)
// same.value == 42

// Use .some(nil) to explicitly set to nil
let cleared = config.copying(value: .some(nil))
// cleared.value == nil

// Set a new value normally
let updated = config.copying(value: 100)
// updated.value == 100
```

## Features

- Works with `struct`, `class`, and `actor` types
- Supports generic types with constraints
- Only specify the properties you want to change
- Automatically skips computed properties and static properties
- Supports optional properties
- Matches the access level of the declared type
- Generates documentation comments
- Emits warnings for properties without type annotations

## Limitations

- Properties must have explicit type annotations (e.g., `let name: String`). Properties using type inference (e.g., `let name = "default"`) will be excluded with a warning.
- Computed properties and static properties are automatically skipped.
- The generated method calls the type's memberwise initializer (for structs) or `init` (for classes/actors), so all stored properties must be included in the initializer.

## Requirements

- Swift 6.2+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+

## License

MIT
