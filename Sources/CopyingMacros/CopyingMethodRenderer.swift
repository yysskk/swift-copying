import SwiftSyntax
import SwiftSyntaxBuilder

/// Renders the `copying` method that `@Copying` adds to a type.
enum CopyingMethodRenderer {
    /// Builds the `copying` method for a type from its name, generic parameters,
    /// access level, and copyable stored properties.
    ///
    /// The generated method takes one optional parameter per stored property,
    /// defaulting to `nil`, and returns a new instance built from the given
    /// arguments falling back to the current values.
    static func render(
        typeName: String,
        genericParameterClause: GenericParameterClauseSyntax?,
        accessLevel: AccessLevel,
        storedProperties: [StoredProperty]
    ) -> DeclSyntax {
        let fullTypeName = makeFullTypeName(name: typeName, genericParameterClause: genericParameterClause)

        // Documentation names a parameter as its label, which carries no escaping:
        // backticks around it would leave the parameter unmatched and the code span
        // reading as a symbol link.
        let documentation =
            storedProperties
            .map {
                "///   - \($0.argumentLabel): The new value for `\($0.argumentLabel)`, or `nil` to keep the current value."
            }
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
            \(raw: accessLevel.rendered)func copying(
            \(raw: parameters)
            ) -> \(raw: fullTypeName) {
                \(raw: typeName)(
            \(raw: arguments)
                )
            }
            """
    }

    /// Returns the type's name with its generic parameters reattached as arguments
    /// (e.g. `Pair<K, V>`), or just the name when the type is not generic.
    private static func makeFullTypeName(
        name: String,
        genericParameterClause: GenericParameterClauseSyntax?
    ) -> String {
        guard let genericParameterClause else {
            return name
        }
        let genericArguments = genericParameterClause.parameters.map { parameter in
            // A pack is referred to by expanding it; the plain name Swift rejects with
            // "pack reference can only appear in pack expansion".
            isParameterPack(parameter) ? "repeat each \(parameter.name.text)" : parameter.name.text
        }
        return "\(name)<\(genericArguments.joined(separator: ", "))>"
    }

    /// Whether `parameter` declares a parameter pack, as `each T` does.
    ///
    /// The `each` is read as a token preceding the parameter's name rather than
    /// through the typed child, which swift-syntax 600 calls `eachKeyword` and later
    /// versions rename to `specifier`; the token itself is the same on every version
    /// this package supports. Only the tokens before the name are considered, so an
    /// `each` appearing in an inherited type is not mistaken for the specifier. A
    /// value generic (`let n: Int`) carries a different specifier and keeps its plain
    /// name, which is how a value generic is referred to anyway.
    private static func isParameterPack(_ parameter: GenericParameterSyntax) -> Bool {
        parameter.tokens(viewMode: .sourceAccurate)
            .prefix { $0.id != parameter.name.id }
            .contains { $0.tokenKind == .keyword(.each) }
    }
}
