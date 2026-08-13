/// A macro that generates a `copying` method for a `struct`, `class`, or `actor`,
/// similar to Kotlin's `copy` function for data classes.
///
/// The generated method takes one optional argument per stored property and
/// returns a new instance with the specified properties replaced and every other
/// property copied from the original.
///
/// ```swift
/// @Copying
/// struct Person {
///     let name: String
///     let age: Int
/// }
///
/// let john = Person(name: "John", age: 30)
/// let olderJohn = john.copying(age: 31)
/// // olderJohn.name == "John", olderJohn.age == 31
/// ```
///
/// Each parameter defaults to `nil`, meaning "keep the current value". For an
/// optional property the parameter is a double optional, so passing the `nil`
/// literal keeps the value while `.some(nil)` resets it; see
/// <doc:OptionalProperties>. For the properties the macro skips and the rules it
/// enforces, see <doc:Limitations>.
///
/// - Note: A `class` or `actor` must provide an initializer shaped like a
///   `struct`'s memberwise initializer — one labelled argument per copyable stored
///   property — because the generated method calls it. If it is missing, the macro
///   warns with the exact signature and a Fix-It that inserts it; see
///   <doc:Limitations>.
/// - Note: A `class` should also be `final`. The generated method returns the type it
///   is attached to, so a subclass inherits one that rebuilds only the superclass and
///   silently discards its own state. The macro warns when the class is not `final`
///   and offers a Fix-It that marks it; see <doc:Limitations>.
/// - Note: The generated method takes the type's access level, capped at the least
///   visible property it copies — the rule Swift applies to a memberwise
///   initializer. Declare the copied properties `public` to keep a `public`
///   `copying` method; see <doc:Limitations>.
@attached(member, names: named(copying))
public macro Copying() = #externalMacro(module: "CopyingMacros", type: "CopyingMacro")
