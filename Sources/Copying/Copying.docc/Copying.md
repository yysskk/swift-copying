# ``Copying``

Generate a Kotlin-style `copying` method that returns a modified copy of a value or reference type.

## Overview

The ``Copying()`` macro attaches a `copying` method to a `struct`, `class`, or `actor`. The method takes one optional argument per stored property and returns a new instance with the arguments you supply replaced and every other property carried over from the original.

```swift
@Copying
struct Person {
    let name: String
    let age: Int
}

let john = Person(name: "John", age: 30)
let olderJohn = john.copying(age: 31)
// olderJohn.name == "John", olderJohn.age == 31
```

This mirrors the `copy` method Kotlin synthesizes for `data class`es, bringing the same ergonomics to Swift's `struct`, `class`, and `actor` types.

## Topics

### Essentials

- <doc:GettingStarted>

### Rules and behavior

- <doc:Limitations>
- <doc:OptionalProperties>

### Macros

- ``Copying()``
