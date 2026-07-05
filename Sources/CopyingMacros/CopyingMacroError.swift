/// An error raised while expanding the `@Copying` macro.
///
/// The macro fails the compilation with a descriptive message when it is applied
/// to an unsupported declaration or encounters a stored property it cannot
/// generate a parameter for.
enum CopyingMacroError: Error, CustomStringConvertible {
    /// The macro was attached to something other than a struct, class, or actor.
    case notStructOrClassOrActor
    /// The declaration has no stored property that can participate in a copy.
    case noStoredProperties
    /// A copyable stored property lacks the explicit type annotation the macro
    /// needs to spell out the corresponding `copying` parameter.
    case missingTypeAnnotation(propertyName: String)

    var description: String {
        switch self {
        case .notStructOrClassOrActor:
            return "@Copying can only be applied to struct, class, or actor declarations"
        case .noStoredProperties:
            return "@Copying requires at least one stored property with explicit type annotation"
        case .missingTypeAnnotation(let propertyName):
            return "@Copying requires an explicit type annotation for '\(propertyName)'"
        }
    }
}
