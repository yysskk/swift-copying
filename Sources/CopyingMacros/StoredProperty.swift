import SwiftSyntax

/// A single stored property that the generated `copying` method can change.
struct StoredProperty {
    /// The property's name, used as both the parameter label and the argument label.
    let name: String
    /// The property's spelled-out type, used verbatim as the `copying` parameter type.
    let type: String
}

extension StoredProperty {
    /// Extracts every stored property that should participate in a copy from the
    /// members of the annotated declaration.
    ///
    /// Members that cannot be copied are skipped: type-level (`static`/`class`) and
    /// `lazy` properties, computed and coroutine-accessor properties, non-identifier
    /// bindings (e.g. tuple patterns), and `let` constants with an initial value
    /// (which are fixed and excluded from the memberwise initializer).
    ///
    /// - Throws: ``CopyingMacroError/missingTypeAnnotation(propertyName:)`` when a
    ///   copyable property omits the explicit type annotation the macro needs.
    static func extract(from declaration: some DeclGroupSyntax) throws -> [StoredProperty] {
        try declaration.memberBlock.members.flatMap { member -> [StoredProperty] in
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return []
            }
            return try storedProperties(in: variable)
        }
    }

    /// Returns the copyable stored properties declared by a single `var`/`let`
    /// declaration, which may bind several properties at once (e.g. `let x: Int, y: Int`).
    private static func storedProperties(in variable: VariableDeclSyntax) throws -> [StoredProperty] {
        // Skip type-level (`static`/`class`) and `lazy` properties. A `static`/`class`
        // property is not part of an instance's state, and a `lazy` property would
        // require a mutating getter to read from `copying`; a fresh copy recomputes
        // it on demand anyway.
        guard !variable.modifiers.contains(where: \.isTypeLevelOrLazy) else {
            return []
        }

        let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)

        // A single declaration can bind multiple properties, so iterate over every
        // binding to make sure none are dropped.
        return try variable.bindings.compactMap { binding -> StoredProperty? in
            // Computed and coroutine-accessor properties are not stored.
            if let accessorBlock = binding.accessorBlock, !isStored(accessorBlock) {
                return nil
            }

            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return nil
            }
            let propertyName = pattern.identifier.text

            // A `let` with an initial value can never hold a different value and is
            // excluded from the memberwise initializer, so it cannot be copied.
            if isLet, binding.initializer != nil {
                return nil
            }

            // The type must be spelled out: it becomes the `copying` parameter type,
            // and a macro only sees syntax, so it cannot infer a type from the
            // initializer. Dropping the property instead would make every copy
            // silently reset it to its default value.
            guard let typeAnnotation = binding.typeAnnotation else {
                throw CopyingMacroError.missingTypeAnnotation(propertyName: propertyName)
            }

            return StoredProperty(name: propertyName, type: typeAnnotation.type.trimmedDescription)
        }
    }

    /// Returns whether an accessor block belongs to a stored property.
    ///
    /// A property is stored only when its accessor block contains nothing but
    /// `willSet`/`didSet` observers. A getter, a setter, or a coroutine accessor
    /// (`_read`/`_modify`) makes it computed or otherwise non-stored.
    private static func isStored(_ accessorBlock: AccessorBlockSyntax) -> Bool {
        switch accessorBlock.accessors {
        case .getter:
            return false
        case .accessors(let accessors):
            return accessors.allSatisfy { accessor in
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    return true
                default:
                    return false
                }
            }
        }
    }
}

extension DeclModifierSyntax {
    /// Whether this modifier makes a property type-level (`static`/`class`) or `lazy`,
    /// in which case it is excluded from copying.
    fileprivate var isTypeLevelOrLazy: Bool {
        switch name.tokenKind {
        case .keyword(.static), .keyword(.class), .keyword(.lazy):
            return true
        default:
            return false
        }
    }
}
