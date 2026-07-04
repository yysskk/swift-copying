import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CopyingMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Get the type name and generic parameters
        let typeName: String
        let fullTypeName: String
        let isClass: Bool

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
            fullTypeName = makeFullTypeName(name: typeName, genericParameterClause: structDecl.genericParameterClause)
            isClass = false
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
            fullTypeName = makeFullTypeName(name: typeName, genericParameterClause: classDecl.genericParameterClause)
            isClass = true
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            typeName = actorDecl.name.text
            fullTypeName = makeFullTypeName(name: typeName, genericParameterClause: actorDecl.genericParameterClause)
            isClass = true
        } else {
            throw CopyingMacroError.notStructOrClassOrActor
        }

        let accessLevel = makeAccessLevelModifier(modifiers: declaration.modifiers)

        // Extract stored properties
        let storedProperties = declaration.memberBlock.members.flatMap { member -> [StoredProperty] in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }

            // Skip static properties
            guard !varDecl.modifiers.contains(where: { $0.name.text == "static" }) else {
                return []
            }

            // A single declaration can declare multiple properties on one line,
            // e.g. `let x: Int, y: Int`. Iterate over every binding so none are dropped.
            return varDecl.bindings.compactMap { binding -> StoredProperty? in
                // Check if it's a stored property (has no accessor block, or only has willSet/didSet)
                if let accessorBlock = binding.accessorBlock {
                    // Check if it's a computed property
                    switch accessorBlock.accessors {
                    case .getter:
                        return nil
                    case .accessors(let accessors):
                        let hasGetOrSet = accessors.contains { accessor in
                            accessor.accessorSpecifier.text == "get" || accessor.accessorSpecifier.text == "set"
                        }
                        if hasGetOrSet {
                            return nil
                        }
                    }
                }

                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    return nil
                }

                let propertyName = pattern.identifier.text

                // Get the type annotation
                guard let typeAnnotation = binding.typeAnnotation else {
                    return nil
                }

                let propertyType = typeAnnotation.type.trimmedDescription

                return StoredProperty(name: propertyName, type: propertyType)
            }
        }

        guard !storedProperties.isEmpty else {
            throw CopyingMacroError.noStoredProperties
        }

        // Generate the copying method
        let parametersList = storedProperties.map { property in
            "    \(property.name): (\(property.type))? = nil"
        }
        let parameters = parametersList.joined(separator: ",\n")

        let argumentsList = storedProperties.map { property in
            "        \(property.name): \(property.name) ?? self.\(property.name)"
        }
        let arguments = argumentsList.joined(separator: ",\n")

        let copyingMethod: DeclSyntax = """
            /// Creates a copy of this instance with the specified properties modified.
            /// - Parameters:
            \(raw: storedProperties.map { "///   - \($0.name): The new value for `\($0.name)`, or `nil` to keep the current value." }.joined(separator: "\n"))
            /// - Returns: A new instance with the specified modifications.
            \(raw: accessLevel)func copying(
            \(raw: parameters)
            ) -> \(raw: fullTypeName) {
                \(raw: isClass ? "return " : "")\(raw: typeName)(
            \(raw: arguments)
                )
            }
            """

        return [copyingMethod]
    }

    /// Returns the access-level modifier (with a trailing space) to apply to the
    /// generated method, derived from the type's declaration modifiers.
    ///
    /// Returns an empty string when the type has no explicit access-level modifier
    /// (i.e. the default `internal`). Two levels are adjusted so that the method
    /// is callable from everywhere the type itself is visible:
    /// - `open` is mapped to `public` because the generated method is a factory
    ///   that never needs to be overridden.
    /// - `private` is mapped to `fileprivate` because a `private` member would be
    ///   confined to the type declaration itself, while a `private` type remains
    ///   usable in the rest of the file.
    private static func makeAccessLevelModifier(modifiers: DeclModifierListSyntax) -> String {
        let accessLevelKeywords: Set<String> = [
            "open", "public", "package", "internal", "fileprivate", "private",
        ]
        guard let modifier = modifiers.first(where: { accessLevelKeywords.contains($0.name.text) }) else {
            return ""
        }
        let keyword: String
        switch modifier.name.text {
        case "open":
            keyword = "public"
        case "private":
            keyword = "fileprivate"
        default:
            keyword = modifier.name.text
        }
        return "\(keyword) "
    }

    private static func makeFullTypeName(name: String, genericParameterClause: GenericParameterClauseSyntax?) -> String {
        guard let genericParameterClause = genericParameterClause else {
            return name
        }
        let genericParameters = genericParameterClause.parameters.map { $0.name.text }.joined(separator: ", ")
        return "\(name)<\(genericParameters)>"
    }
}

struct StoredProperty {
    let name: String
    let type: String
}

enum CopyingMacroError: Error, CustomStringConvertible {
    case notStructOrClassOrActor
    case noStoredProperties

    var description: String {
        switch self {
        case .notStructOrClassOrActor:
            return "@Copying can only be applied to struct, class, or actor declarations"
        case .noStoredProperties:
            return "@Copying requires at least one stored property with explicit type annotation"
        }
    }
}

@main
struct CopyingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyingMacro.self,
    ]
}
