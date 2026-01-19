# swift-copying

A Swift Macro that generates a `copying` method for struct and class types, similar to Kotlin's `copy` function for data classes.

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

## Features

- Works with both `struct` and `class` types
- Only specify the properties you want to change
- Automatically skips computed properties and static properties
- Supports optional properties
- Generates documentation comments

## Requirements

- Swift 6.2+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+

## License

MIT
