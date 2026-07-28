import SwiftDiagnostics
import SwiftSyntax

/// A single stored property that the generated `copying` method can change.
struct StoredProperty {
    /// The property's name, used as both the parameter label and the argument label.
    let name: String
    /// The property's type, spelled the way the declaration spells it.
    let type: TypeSyntax

    /// The type the `copying` parameter wraps in an optional.
    ///
    /// This is the declared type, except for an implicitly unwrapped optional (`T!`),
    /// which is spelled `T?`. Swift only accepts `!` at the top level of a property's
    /// or a parameter's type (SE-0054), so the `(T!)? = nil` parameter the renderer
    /// would otherwise write is rejected outright. `T!` denotes the very same type as
    /// `T?` — the `!` only asks for implicit unwrapping at each use — so the parameter
    /// still accepts exactly the same arguments, and the property still receives the
    /// optional it is declared with.
    var parameterType: TypeSyntax {
        guard let implicitlyUnwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) else {
            return type
        }
        return TypeSyntax(OptionalTypeSyntax(wrappedType: implicitlyUnwrapped.wrappedType.trimmed))
    }
}

extension StoredProperty {
    /// Extracts every stored property that should participate in a copy from the
    /// members of the annotated declaration, together with any diagnostics the
    /// macro should report.
    ///
    /// Members that cannot be copied are skipped: type-level (`static`/`class`) and
    /// `lazy` properties, computed and coroutine-accessor properties, and `let`
    /// constants with an initial value (which are fixed and excluded from the
    /// memberwise initializer).
    ///
    /// Two problems are reported as diagnostics rather than silently skipped,
    /// because doing so would corrupt copies:
    /// - A copyable property whose type is left to inference, e.g. `var count = 0`.
    ///   The macro only sees syntax and cannot infer the type; dropping the property
    ///   would make every copy silently reset it to its default value. An annotation
    ///   shared with a later binding in the same declaration does count as spelled
    ///   out — see `declaredType(of:at:in:)`.
    /// - A `var` that binds several properties through a tuple pattern
    ///   (e.g. `var (a, b) = (0, 0)`). Such properties are part of the memberwise
    ///   initializer with defaults, so skipping them would make every copy silently
    ///   reset them. A `let` tuple binding is skipped silently: it is immutable and
    ///   Swift does not allow it as struct storage anyway.
    ///
    /// Diagnostics are collected across all bindings so a single compilation reports
    /// every offending property at once.
    static func extract(
        from declaration: some DeclGroupSyntax
    ) -> (properties: [StoredProperty], diagnostics: [Diagnostic]) {
        var properties: [StoredProperty] = []
        var diagnostics: [Diagnostic] = []
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            collectStoredProperties(in: variable, into: &properties, diagnostics: &diagnostics)
        }
        return (properties, diagnostics)
    }

    /// Appends the copyable stored properties declared by a single `var`/`let`
    /// declaration (which may bind several properties, e.g. `let x: Int, y: Int`),
    /// recording a diagnostic for any binding that cannot be copied safely.
    private static func collectStoredProperties(
        in variable: VariableDeclSyntax,
        into properties: inout [StoredProperty],
        diagnostics: inout [Diagnostic]
    ) {
        // Skip type-level (`static`/`class`) and `lazy` properties. A `static`/`class`
        // property is not part of an instance's state, and a `lazy` property would
        // require a mutating getter to read from `copying`; a fresh copy recomputes
        // it on demand anyway.
        guard !variable.modifiers.contains(where: \.isTypeLevelOrLazy) else {
            return
        }

        let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
        let bindings = Array(variable.bindings)

        for (index, binding) in bindings.enumerated() {
            // Computed and coroutine-accessor properties are not stored.
            if let accessorBlock = binding.accessorBlock, !isStored(accessorBlock) {
                continue
            }

            // A tuple pattern binds several properties at once and cannot be copied
            // individually. Only `var` is flagged: a `var` tuple is part of the
            // memberwise initializer, so skipping it would silently reset those
            // properties on every copy.
            if binding.pattern.is(TuplePatternSyntax.self) {
                if !isLet {
                    diagnostics.append(CopyingDiagnostic.tuplePatternBinding.diagnostic(at: binding.pattern))
                }
                continue
            }

            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            let propertyName = pattern.identifier.text

            // A `let` with an initial value can never hold a different value and is
            // excluded from the memberwise initializer, so it cannot be copied.
            if isLet, binding.initializer != nil {
                continue
            }

            guard let type = declaredType(of: binding, at: index, in: bindings) else {
                diagnostics.append(
                    CopyingDiagnostic.missingTypeAnnotation(propertyName: propertyName).diagnostic(at: binding)
                )
                continue
            }

            properties.append(StoredProperty(name: propertyName, type: type.trimmed))
        }
    }

    /// Returns the type `bindings[index]` spells out, or `nil` when the declaration
    /// leaves it to inference and the macro therefore cannot see it.
    ///
    /// A declaration may write one annotation once and share it across several
    /// bindings (`var x, y: Int` declares two `Int` properties). SwiftSyntax attaches
    /// that annotation only to the binding that carries it, so a binding without one
    /// takes the annotation of a later binding in the same declaration.
    ///
    /// The sharing stops at the first binding with an initial value, which types
    /// itself by inference instead: that is why Swift accepts `var x = 0, y: String`
    /// yet rejects `var x, y: Int = 0`.
    private static func declaredType(
        of binding: PatternBindingSyntax,
        at index: Int,
        in bindings: [PatternBindingSyntax]
    ) -> TypeSyntax? {
        if let typeAnnotation = binding.typeAnnotation {
            return typeAnnotation.type
        }
        guard binding.initializer == nil else {
            return nil
        }
        for laterBinding in bindings[(index + 1)...] {
            guard laterBinding.initializer == nil else {
                return nil
            }
            if let typeAnnotation = laterBinding.typeAnnotation {
                return typeAnnotation.type
            }
        }
        return nil
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
