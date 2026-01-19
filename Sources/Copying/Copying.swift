/// A macro that generates a `copying` method for struct or class types,
/// similar to Kotlin's `copy` function for data classes.
///
/// The generated method allows creating a modified copy of an instance
/// by specifying only the properties you want to change.
///
/// Example:
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
@attached(member, names: named(copying))
public macro Copying() = #externalMacro(module: "CopyingMacros", type: "CopyingMacro")
