# Limitations and Rules

Learn which stored properties `copying` includes and what the macro requires of your declarations.

## Overview

``Copying()`` generates a parameter only for the stored properties that can take part in a copy. It skips some declarations silently, rejects others with a compile-time error, and warns about the ones whose correctness turns on code it cannot see.

### Properties that are skipped

These properties are left out of `copying` without any diagnostic, because copying them makes no sense or is unnecessary:

- **Type properties** declared with `static` (or `class`), which are not part of an instance's state.
- **Computed properties**, whether written as a single expression, an explicit `get`, or a `get`/`set` pair. Properties that only observe changes with `willSet`/`didSet` are still stored and *are* included.
- **`lazy` properties.** Reading one inside `copying` would require a mutating getter on a `struct`, and a fresh copy recomputes the value on demand anyway.
- **`let` constants with an initial value**, such as `let maxValue: Int = 100`. The memberwise initializer excludes them, so a copy has no way to be handed one — see below.
- **Immutable tuple bindings**, such as `let (x, y) = (0, 0)` (allowed in a `class` or `actor`). They are constants, so there is nothing to vary. The mutable `var` form is rejected instead — see below.

A `let` with an initial value deserves a second look, because skipping it means the *value* is produced again rather than carried over. A copy is a new instance, so its initial value expression runs for the copy too:

```swift
@Copying
struct Record {
    let id: UUID = UUID()
    var name: String
}

let record = Record(name: "first")
record.copying(name: "second").id   // a different UUID
```

For a literal such as `100` that comes to the same thing. For an expression that yields a new value each time — `UUID()`, `Date()`, a counter — the copy does not share the original's. When the value has to survive a copy, drop the initial value so the property takes part in copying, and supply the default through an initializer instead:

```swift
@Copying
struct Record {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) { … }
}
```

### Declarations that are rejected

The macro emits an error, so the mistake surfaces at compile time instead of corrupting copies:

- **A copyable property whose type is left to inference**, such as `var count = 0`. The macro sees only syntax and cannot infer the type, so annotate it: `var count: Int = 0`. (Left unchecked, the property would silently reset to its default on every copy.) An annotation shared across the bindings of one declaration, as in `var x, y: Int`, is spelled out for all of them and needs no change.
- **A `var` bound through a tuple pattern**, such as `var (x, y) = (0, 0)`. Declare each property on its own line so the macro can address them individually.
- **A type with no copyable stored properties at all.** `@Copying` needs at least one property it can vary.
- **Applying `@Copying` to anything other than a `struct`, `class`, or `actor`.**
- **A copyable property named after the type it belongs to**, such as a `Money` in `struct Money`. The generated method takes a parameter of that name, and the call that builds the copy sits in its body, so `Money(Money: …)` reads `Money` as the parameter rather than the type. Building the copy with `Self(…)` would sidestep it, but `Self` in a `class` resolves dynamically and so needs a `required` initializer, which the macro cannot ask a non-`final` class for having just advised it to be `final`. Renaming the property is the change that leaves every supported declaration working.
- **A copyable property with an opaque type**, such as `var value: some Equatable`. Written in a parameter, `some P` declares a fresh generic parameter for the caller to choose (SE-0341) rather than naming the property's own type, so the copy would not type-check. An `any P` existential is a type in its own right and copies like any other.
- **A copyable property whose type expands a parameter pack**, such as `let values: (repeat each T)`. The type itself may be generic over a pack — `struct Bundle<each T>` is copied like any other generic type, and the generated method returns `Bundle<repeat each T>` — but a copy is built by passing each property to an initializer, and Swift does not compile such a call for a value that expands a pack, whether the initializer is memberwise or written by hand. A type that stores one needs a `copying` written by hand.
- **A copyable property declared inside `#if`**, such as a `var inset: CGFloat` under `#if os(iOS)`. A macro is handed the declaration before the directives are resolved and cannot know which branch a build takes, so no single expansion is right for all of them. Declare the property unconditionally and vary its *value* by configuration instead. A member inside `#if` that a copy never carries anyway — a computed, `static`, or `lazy` property, or a `let` with an initial value — is skipped as silently as it is outside one.

When several properties break the rules, every violation is reported in a single build.

### Classes that can be subclassed

`copying` builds the copy by calling the annotated type's own initializer and returns it as that type. A subclass inherits that method unchanged, so a copy taken through it rebuilds only the superclass:

```swift
@Copying
class Base {
    var a: Int
    init(a: Int) { self.a = a }
}
// ⚠️ @Copying returns a new 'Base' from 'copying', so a subclass inherits
//    one that discards its own state; mark 'Base' as 'final'
//    Fix-It: Mark 'Base' as 'final'

final class Derived: Base {
    var b: Int
    init(a: Int, b: Int) { self.b = b; super.init(a: a) }
}

Derived(a: 1, b: 2).copying(a: 3)   // a 'Base' both statically and dynamically — 'b' is gone
```

Nothing in the language catches this: the call type-checks and the copy is silently the wrong instance. So the macro warns on every `class` that is not `final` and offers a Fix-It that marks it so — the same restriction Kotlin puts on a `data class`, for the same reason. A `struct` and an `actor` cannot be subclassed, so neither is ever flagged.

The Fix-It writes `final` after any modifier the class already carries, giving `public final class`. An `open` class becomes `public final`, because `open` and `final` contradict each other; that keeps the class visible everywhere it was and takes away only the subclassing.

It is a warning rather than an error because a class nothing subclasses copies itself perfectly well. `final` is how you say that, and saying it is what makes the copy correct.

Annotating the subclass as well does not help. `@Copying` sees only the properties declared on the declaration it is attached to, so on a subclass it generates a `copying` over those alone, which calls an initializer taking those alone. The inherited properties are not carried across — they come back as whatever that initializer leaves them:

```swift
@Copying
final class Derived: Base {
    var b: Int
    init(b: Int) { self.b = b; super.init(a: 0) }
}

let derived = Derived(b: 2)
derived.a = 7
derived.copying(b: 3).a   // 0, not 7 — 'copying(b:)' rebuilds through 'init(b:)'
```

The two methods are overloads rather than an override, so this trades the lost subclass state for lost superclass state instead of fixing anything.

Overriding `copying` by hand does fix it, inside the module that declares the superclass. Swift lets an override narrow the return type to the subclass:

```swift
final class Derived: Base {
    var b: Int
    init(a: Int, b: Int) { self.b = b; super.init(a: a) }

    override func copying(a: Int? = nil) -> Derived {
        Derived(a: a ?? self.a, b: self.b)
    }
}
```

From another module it is not an option. The generated method is never `open` — an `open` class produces at most a `public` one, and less when it copies a less visible property — which Swift refuses to let a subclass override outside the module that declares it. A subclass there is stuck with the inherited `copying` and has no way to correct it, so an `open` class is flagged like any other — even though `final` is the opposite of what `open` asks for. A type genuinely meant to be subclassed across modules is a type to write `copying` for by hand.

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

Property types are not compared, only argument labels, so a typealias or a generic parameter never trips the check. A variadic parameter is the one exception to matching by label: it gathers its arguments one by one, while the generated call passes the property's value as a whole, so `init(id: Int, tags: String...)` does not satisfy a `tags: [String]` property. It counts as an extra parameter the call leaves out, exactly as `notes:` does above.

Labels are compared as identifiers, so the backticks that escape a property name make no difference. A property declared `` var `default`: String `` is satisfied by `init(default value: String)`, the way Swift spells that label, and the warning names the signature the way Swift writes a compound name, `init(default:)`. The initializer the Fix-It writes escapes the identifier where the language requires it.

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

### Why the initializer rules are warnings

Both initializer rules are warnings rather than errors, because a macro only ever sees the declaration it is attached to. An initializer added in an extension, or inherited from a superclass, satisfies the generated call while being invisible to the check:

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

An initializer declared inside `#if` is the same blind spot taken one step further: it silences the check outright. Warning would be wrong wherever that branch is active, and the Fix-It would write a second initializer with the signature the first one already has.

### The access level of the generated method

The generated method takes the annotated type's access level, capped at the least visible property it copies. This is the rule Swift applies to a struct's memberwise initializer, and for the same two reasons:

```swift
struct Token { … }            // internal

@Copying
public struct Session {
    public let id: String
    private var token: String
}
// The method is 'private', not 'public'.
```

A method more visible than a property it copies would hand out what the property's access level withholds: a `public copying(id:token:)` lets any module build a `Session` that varies `token`, which is exactly what `private` is there to prevent. And a method more visible than a copied property's *type* does not compile at all — a `public` method taking `Token` is rejected with "method cannot be declared public because its parameter uses an internal type". Capping at the property removes both.

The two levels the macro adjusts are unchanged: `open` counts as `public`, since the generated method is a factory that is never overridden, and a `private` *type* yields a `fileprivate` method, since a `private` member would be confined to the type declaration while the type itself stays usable in the rest of the file. A `private` *property* is the reverse: it keeps the method `private`, which reaches the type declaration and its extensions in the same file — exactly as far as the property does.

Two kinds of member never lower the cap. A modifier that constrains only the setter, such as `private(set)`, leaves read access alone, and `copying` reads a property and passes the value to an initializer rather than assigning through it:

```swift
@Copying
public struct Scoreboard {
    public private(set) var score: Int      // 'public func copying(score:)'
}
```

And a member the method does not copy — `static`, `lazy`, computed, or a `let` with an initial value — has no parameter to hide, however private it is.

To keep a `public` copying method, declare the copied properties `public`.

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

### Noncopyable types

A `~Copyable` type is supported as long as the properties `copying` carries are themselves copyable. Methods on such a type borrow `self` by default, which is all `copying` needs: it reads each property and returns a freshly built instance.

```swift
@Copying
struct Buffer: ~Copyable {
    var id: Int
    var label: String
}
```

A *noncopyable property* is a different matter, and one the macro cannot see. The generated call reads the property to pass it on, which consumes a noncopyable value, so the code does not compile — the same blind spot as a wrapper without `init(wrappedValue:)`: whether a type is copyable is not something the property's spelling says.
