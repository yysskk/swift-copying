import SwiftSyntax
import SwiftSyntaxBuilder

/// Renders the `copying` method that `@Copying` adds to a type.
enum CopyingMethodRenderer {
    /// Builds the `copying` method for a type from its name, generic parameters,
    /// declaration modifiers, and copyable stored properties.
    ///
    /// The generated method takes one optional parameter per stored property,
    /// defaulting to `nil`, and returns a new instance built from the given
    /// arguments falling back to the current values.
    static func render(
        typeName: String,
        genericParameterClause: GenericParameterClauseSyntax?,
        modifiers: DeclModifierListSyntax,
        storedProperties: [StoredProperty]
    ) -> DeclSyntax {
        let fullTypeName = makeFullTypeName(name: typeName, genericParameterClause: genericParameterClause)
        let accessLevel = modifiers.accessLevelForGeneratedMembers

        let documentation =
            storedProperties
            .map { "///   - \($0.name): The new value for `\($0.name)`, or `nil` to keep the current value." }
            .joined(separator: "\n")
        let parameters =
            storedProperties
            .map { "    \($0.name): (\($0.parameterType))? = nil" }
            .joined(separator: ",\n")
        let arguments =
            storedProperties
            .map { "        \($0.name): \($0.name) ?? self.\($0.name)" }
            .joined(separator: ",\n")

        // A single-expression body relies on the implicit `return` (SE-0255), which
        // applies uniformly to structs, classes, and actors.
        return """
            /// Creates a copy of this instance with the specified properties modified.
            /// - Parameters:
            \(raw: documentation)
            /// - Returns: A new instance with the specified modifications.
            \(raw: accessLevel)func copying(
            \(raw: parameters)
            ) -> \(raw: fullTypeName) {
                \(raw: typeName)(
            \(raw: arguments)
                )
            }
            """
    }

    /// Returns the type's name with its generic parameter names reattached
    /// (e.g. `Pair<K, V>`), or just the name when the type is not generic.
    private static func makeFullTypeName(
        name: String,
        genericParameterClause: GenericParameterClauseSyntax?
    ) -> String {
        guard let genericParameterClause else {
            return name
        }
        let genericParameters = genericParameterClause.parameters.map(\.name.text).joined(separator: ", ")
        return "\(name)<\(genericParameters)>"
    }
}
