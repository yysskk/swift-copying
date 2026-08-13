import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// The implementation of the `@Copying` member macro.
///
/// It generates a `copying` method on the annotated struct, class, or actor that
/// returns a new instance with a chosen subset of stored properties replaced. The
/// heavy lifting is delegated to ``StoredProperty/extract(from:)`` (which selects
/// the copyable properties and reports problematic ones) and
/// ``CopyingMethodRenderer`` (which renders the method); this type only admits the
/// declaration and orchestrates the steps.
public struct CopyingMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let target = CopyingTarget(declaration: declaration) else {
            throw CopyingDiagnostic.unsupportedDeclaration.error(at: node)
        }

        let storedProperties = try StoredProperty.extract(from: declaration)
        guard !storedProperties.isEmpty else {
            throw CopyingDiagnostic.noStoredProperties.error(at: node)
        }

        // The method and the initializer the Fix-It writes share one level, so a copy
        // is never buildable from somewhere the state it carries is hidden.
        let accessLevel = AccessLevel.forGeneratedMembers(
            ofTypeWith: declaration.modifiers,
            copying: storedProperties
        )

        // A class that can still be subclassed hands `copying` down to its subclasses,
        // and an inherited one rebuilds only the superclass — see ``SubclassingHazard``.
        // This only warns, and the method is still generated: a class nothing subclasses
        // copies itself correctly.
        if let subclassingHazard = SubclassingHazard(declaration: declaration) {
            context.diagnose(
                CopyingDiagnostic
                    .subclassableClass(typeName: target.typeName)
                    .diagnostic(at: subclassingHazard.anchor, fixIts: [subclassingHazard.fixIt])
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
                    .missingInitializer(typeName: target.typeName, signature: initializerRequirement.signature)
                    .diagnostic(
                        at: node,
                        fixIts: [initializerRequirement.fixIt(insertingInto: declaration, accessLevel: accessLevel)]
                    )
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

        return [
            CopyingMethodRenderer.render(
                typeName: target.typeName,
                genericParameterClause: target.genericParameterClause,
                accessLevel: accessLevel,
                storedProperties: storedProperties
            )
        ]
    }
}

/// A declaration `@Copying` can generate a `copying` method for, along with what
/// rendering that method needs from it.
///
/// The three kinds are listed out rather than recognized by their syntax traits
/// alone. An `enum` is also a named declaration with generic parameters, so a trait
/// check would admit one, and an enum has no stored properties to copy.
private struct CopyingTarget {
    /// The type's name, as the generated method spells it in the call it builds.
    let typeName: String
    /// The type's generic parameters, if any, to reattach to the return type.
    let genericParameterClause: GenericParameterClauseSyntax?

    /// Creates the target `declaration` describes, or `nil` when the macro does not
    /// support that kind of declaration.
    init?(declaration: some DeclGroupSyntax) {
        guard
            declaration.is(StructDeclSyntax.self)
                || declaration.is(ClassDeclSyntax.self)
                || declaration.is(ActorDeclSyntax.self),
            let named = declaration.asProtocol(NamedDeclSyntax.self),
            let generic = declaration.asProtocol(WithGenericParametersSyntax.self)
        else {
            return nil
        }
        typeName = named.name.text
        genericParameterClause = generic.genericParameterClause
    }
}
