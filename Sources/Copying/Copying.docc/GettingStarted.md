# Getting Started

Add a `copying` method to a type and derive modified instances from it.

## Overview

Apply ``Copying()`` to any `struct`, `class`, or `actor` whose stored properties carry explicit type annotations. The macro generates a `copying` method with one optional parameter per copyable stored property, each defaulting to `nil` so you only pass the properties you want to change.

### Structs

A `struct` needs nothing beyond the attribute, because it already has a memberwise initializer:

```swift
@Copying
struct Person {
    let name: String
    let age: Int
    let email: String
}

let john = Person(name: "John", age: 30, email: "john@example.com")

let olderJohn = john.copying(age: 31)
let renamed = john.copying(name: "Johnny", email: "johnny@example.com")
```

### Classes and actors

A `class` or `actor` must provide an initializer shaped like a `struct`'s memberwise initializer — one argument per copyable stored property, labelled with the property's own name — because the generated method calls it:

```swift
@Copying
final class User {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

let user = User(id: 1, name: "Ada")
let renamed = user.copying(name: "Grace")
```

Forget that initializer and the macro tells you which one to add, with a Fix-It that writes it for you, rather than letting the mistake surface as an error inside the generated code:

```swift
@Copying
final class User {
    let id: Int
    let name: String
}
// ⚠️ @Copying requires 'User' to declare 'init(id:name:)',
//    which the generated 'copying' method calls
//    Fix-It: Add 'init(id:name:)'
```

See <doc:Limitations> for exactly which declarations are checked and why this is a warning.

An `actor`'s `copying` method is actor-isolated, so call it with `await` from outside the actor:

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
let advanced = await counter.copying(value: 10)
```

## See Also

- <doc:Limitations>
- <doc:OptionalProperties>
