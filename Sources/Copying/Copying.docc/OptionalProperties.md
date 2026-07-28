# Optional Properties

Understand how `copying` tells "keep the current value" apart from "reset to `nil`".

## Overview

Every `copying` parameter defaults to `nil`, meaning "leave this property unchanged". For a non-optional property that reads naturally. For an *optional* property the parameter becomes a double optional (for example `Int??`), which preserves the ability to reset the property — at the cost of one subtlety worth knowing.

Consider a type with an optional stored property:

```swift
@Copying
struct Config {
    let name: String
    let timeout: Int?
}

let config = Config(name: "default", timeout: 30)
```

### Keeping the current value

Omit the argument, or pass the bare `nil` literal. Both leave `timeout` at `30`:

```swift
config.copying()              // timeout == 30
config.copying(timeout: nil)  // timeout == 30
```

The `nil` literal binds to the *outer* optional, which `copying` reads as "no new value given".

### Resetting to `nil`

Wrap the new value in `.some` to reset the property:

```swift
config.copying(timeout: .some(nil))  // timeout == nil
```

A value already typed as the property's optional type flattens into the inner optional, so passing one that holds `nil` resets the property too:

```swift
let newTimeout: Int? = nil
config.copying(timeout: newTimeout)  // timeout == nil
```

> Important: Because the bare `nil` literal means "keep", you cannot reset an optional with `copying(timeout: nil)`. Use `.some(nil)`, or pass a value of the property's own optional type.

### Implicitly unwrapped optionals

A property declared `T!` is an optional as well, so `copying` treats it as one and everything above applies unchanged:

```swift
@Copying
final class Screen {
    var subtitle: String!

    init(subtitle: String!) { … }
}

let screen = Screen(subtitle: "Welcome")
screen.copying()                      // subtitle == "Welcome"
screen.copying(subtitle: "Hello")     // subtitle == "Hello"
screen.copying(subtitle: .some(nil))  // subtitle == nil
```

The parameter itself is spelled `(String?)?` rather than `(String!)?`, because Swift only accepts `!` at the top level of a property's or a parameter's type and here it is nested in the outer optional. That is the same type either way, so the parameter takes the same arguments, and the property is still implicitly unwrapped in the copy.
