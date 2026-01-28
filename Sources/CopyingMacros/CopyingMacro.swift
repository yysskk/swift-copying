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

        // Extract stored properties
        let storedProperties = declaration.memberBlock.members.compactMap { member -> StoredProperty? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            // Skip computed properties and static properties
            guard !varDecl.modifiers.contains(where: { $0.name.text == "static" }) else {
                return nil
            }

            // Check if it's a stored property (has no accessor block, or only has willSet/didSet)
            guard let binding = varDecl.bindings.first else {
                return nil
            }

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

        guard !storedProperties.isEmpty else {
            throw CopyingMacroError.noStoredProperties
        }

        // Generate the copying method
        let parametersList = storedProperties.map { property in
            "    \(property.name): \(property.type)? = nil"
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
            public func copying(
            \(raw: parameters)
            ) -> \(raw: fullTypeName) {
                \(raw: isClass ? "return " : "")\(raw: typeName)(
            \(raw: arguments)
                )
            }
            """

        return [copyingMethod]
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
