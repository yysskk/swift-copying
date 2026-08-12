import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// The implementation of the `@Copying` member macro.
///
/// It generates a `copying` method on the annotated struct, class, or actor that
/// returns a new instance with a chosen subset of stored properties replaced. The
/// heavy lifting is delegated to ``StoredProperty/extract(from:)`` (which selects
/// the copyable properties and reports problematic ones) and
/// ``CopyingMethodRenderer`` (which renders the method); this type only dispatches
/// on the declaration kind and orchestrates the two steps.
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
            throw CopyingDiagnostic.unsupportedDeclaration.error(at: node)
        }

        let storedProperties = try StoredProperty.extract(from: declaration)
        guard !storedProperties.isEmpty else {
            throw CopyingDiagnostic.noStoredProperties.error(at: node)
        }

        // A class that can still be subclassed hands `copying` down to its subclasses,
        // and an inherited one rebuilds only the superclass — see ``SubclassingHazard``.
        // This only warns, and the method is still generated: a class nothing subclasses
        // copies itself correctly.
        if let subclassingHazard = SubclassingHazard(declaration: declaration) {
            context.diagnose(
                CopyingDiagnostic
                    .subclassableClass(typeName: typeName)
                    .diagnostic(at: subclassingHazard.anchor, fixIts: [subclassingHazard.fixIt()])
            )
        }

        // Report the initializer the copy needs against the declaration itself, so the
        // mistake surfaces there instead of as an error inside the expansion, pointing
        // at generated code the author never wrote. These only warn, and the method is
        // still generated: the requirement may be met by an initializer a macro cannot
        // see.
        let initializerRequirement = InitializerRequirement(storedProperties: storedProperties)
        switch initializerRequirement.shortfall(of: declaration) {
        case .noInitializer:
            context.diagnose(
                CopyingDiagnostic
                    .missingInitializer(typeName: typeName, signature: initializerRequirement.signature)
                    .diagnostic(at: node, fixIts: [initializerRequirement.fixIt(insertingInto: declaration)])
            )
        case .unusableInitializer(let initializer):
            // Anchored at the initializer itself: it is the thing to change, and the
            // author cannot simply add the required one alongside it, since Swift
            // rejects a plain overload of a failable or throwing initializer.
            context.diagnose(
                CopyingDiagnostic
                    .unusableInitializer(signature: initializerRequirement.signature)
                    .diagnostic(at: initializer.initKeyword)
            )
        case nil:
            break
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
