import SwiftSyntax
import SwiftSyntaxMacros

/// The implementation of the `@Copying` member macro.
///
/// It generates a `copying` method on the annotated struct, class, or actor that
/// returns a new instance with a chosen subset of stored properties replaced. The
/// heavy lifting is delegated to ``StoredProperty/extract(from:)`` (which selects
/// the copyable properties) and ``CopyingMethodRenderer`` (which renders the
/// method); this type only dispatches on the declaration kind and orchestrates the
/// two steps.
public struct CopyingMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let typeName: String
        let genericParameterClause: GenericParameterClauseSyntax?
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
            genericParameterClause = structDecl.genericParameterClause
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
            genericParameterClause = classDecl.genericParameterClause
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            typeName = actorDecl.name.text
            genericParameterClause = actorDecl.genericParameterClause
        } else {
            throw CopyingMacroError.notStructOrClassOrActor
        }

        let storedProperties = try StoredProperty.extract(from: declaration)
        guard !storedProperties.isEmpty else {
            throw CopyingMacroError.noStoredProperties
        }

        let copyingMethod = CopyingMethodRenderer.render(
            typeName: typeName,
            genericParameterClause: genericParameterClause,
            modifiers: declaration.modifiers,
            storedProperties: storedProperties
        )
        return [copyingMethod]
    }
}
