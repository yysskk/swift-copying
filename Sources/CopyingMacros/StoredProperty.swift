import SwiftDiagnostics
import SwiftSyntax

/// A single stored property that the generated `copying` method can change.
struct StoredProperty {
    /// The property's name, spelled the way the declaration spells it — backticks
    /// included — as generated code has to write it to refer to the property.
    let name: String
    /// The property's name without the backticks that escape it, which is how an
    /// initializer's argument label and a compound name such as `init(default:)`
    /// spell it.
    let argumentLabel: String
    /// The property's type, spelled the way the declaration spells it.
    let type: TypeSyntax
    /// The level the property can be read at, which caps the level of the members the
    /// macro generates — see ``AccessLevel/forGeneratedMembers(ofTypeWith:copying:)``.
    let accessLevel: AccessLevel

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
    /// members of the annotated declaration.
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
    ///   out — see `declaredTypes(in:)`.
    /// - A `var` that binds several properties through a tuple pattern
    ///   (e.g. `var (a, b) = (0, 0)`). Such properties are part of the memberwise
    ///   initializer with defaults, so skipping them would make every copy silently
    ///   reset them. A `let` tuple binding is skipped silently: it is immutable and
    ///   Swift does not allow it as struct storage anyway.
    /// - A property a copy would carry that is declared inside `#if`. Which
    ///   properties such a directive contributes depends on the build configuration,
    ///   which a macro cannot know — see `conditionalDiagnostics(in:)`.
    ///
    /// - Throws: A ``SwiftDiagnostics/DiagnosticsError`` carrying every offending
    ///   binding, so a single compilation reports them all at once.
    static func extract(from declaration: some DeclGroupSyntax) throws -> [StoredProperty] {
        var properties: [StoredProperty] = []
        var diagnostics: [Diagnostic] = []

        for member in declaration.memberBlock.members {
            if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
                diagnostics.append(contentsOf: conditionalDiagnostics(in: ifConfig))
                continue
            }

            for (_, outcome) in classifiedBindings(of: member) {
                switch outcome {
                case .copyable(let property):
                    properties.append(property)
                case .problem(let diagnostic):
                    diagnostics.append(diagnostic)
                case .notCopyable:
                    break
                }
            }
        }

        guard diagnostics.isEmpty else {
            throw DiagnosticsError(diagnostics: diagnostics)
        }
        return properties
    }

    /// A diagnostic for every property inside `ifConfig` that a copy would have to
    /// carry.
    ///
    /// Such a property exists only on the build configurations its branch is active
    /// on, and no single expansion is right for all of them: the generated call
    /// leaves the property out, which fails to compile where the branch is active —
    /// or, when the initializer defaults that parameter, silently resets the property
    /// on every copy. Members a copy never carries anyway, such as a computed or
    /// `static` one, stay silently skipped exactly as they are outside `#if`.
    private static func conditionalDiagnostics(in ifConfig: IfConfigDeclSyntax) -> [Diagnostic] {
        ifConfig.conditionalMembers
            .flatMap(classifiedBindings(of:))
            .filter { _, outcome in outcome.concernsACopy }
            .map { binding, _ in CopyingDiagnostic.conditionalStoredProperty.diagnostic(at: binding) }
    }

    /// How each binding `member` declares takes part in a copy, paired with the
    /// binding itself, or nothing at all when the member declares no property a copy
    /// could carry.
    private static func classifiedBindings(
        of member: MemberBlockItemSyntax
    ) -> [(binding: PatternBindingSyntax, outcome: BindingOutcome)] {
        // Skip type-level (`static`/`class`) and `lazy` properties. A `static`/`class`
        // property is not part of an instance's state, and a `lazy` property would
        // require a mutating getter to read from `copying`; a fresh copy recomputes
        // it on demand anyway.
        guard let variable = member.decl.as(VariableDeclSyntax.self),
            !variable.modifiers.contains(anyOf: .static, .class, .lazy)
        else {
            return []
        }

        // The modifiers sit on the declaration, so every binding it introduces —
        // `private let width, height: Int` declares two — shares its access level.
        let accessLevel = AccessLevel(ofPropertyWith: variable.modifiers)
        let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
        return zip(variable.bindings, declaredTypes(in: variable.bindings)).map { binding, declaredType in
            (binding, outcome(of: binding, declaredType: declaredType, isLet: isLet, accessLevel: accessLevel))
        }
    }

    /// How a single binding takes part in a copy.
    private enum BindingOutcome {
        /// The binding declares a property the copy passes on.
        case copyable(StoredProperty)
        /// The binding cannot be copied, and leaving it out would corrupt copies.
        case problem(Diagnostic)
        /// The binding declares nothing a copy has to carry.
        case notCopyable

        /// Whether a copy has to account for this binding, either by carrying the
        /// property or by reporting that it cannot.
        var concernsACopy: Bool {
            switch self {
            case .copyable, .problem:
                return true
            case .notCopyable:
                return false
            }
        }
    }

    /// Classifies one binding of a `var`/`let` declaration, given the type it spells
    /// out (see `declaredTypes(in:)`), whether the declaration binds constants, and
    /// the level the declaration can be read at.
    private static func outcome(
        of binding: PatternBindingSyntax,
        declaredType: TypeSyntax?,
        isLet: Bool,
        accessLevel: AccessLevel
    ) -> BindingOutcome {
        // Computed and coroutine-accessor properties are not stored.
        if let accessorBlock = binding.accessorBlock, !isStored(accessorBlock) {
            return .notCopyable
        }

        // A tuple pattern binds several properties at once and cannot be copied
        // individually. Only `var` is flagged: a `var` tuple is part of the
        // memberwise initializer, so skipping it would silently reset those
        // properties on every copy.
        if binding.pattern.is(TuplePatternSyntax.self) {
            guard !isLet else {
                return .notCopyable
            }
            return .problem(CopyingDiagnostic.tuplePatternBinding.diagnostic(at: binding.pattern))
        }

        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return .notCopyable
        }

        // A `let` with an initial value can never hold a different value and is
        // excluded from the memberwise initializer, so it cannot be copied.
        if isLet, binding.initializer != nil {
            return .notCopyable
        }

        guard let declaredType else {
            let propertyName = pattern.identifier.text
            return .problem(CopyingDiagnostic.missingTypeAnnotation(propertyName: propertyName).diagnostic(at: binding))
        }

        // A value whose type expands a parameter pack, such as `(repeat each T)`,
        // cannot be passed to an initializer, which is how a copy is built.
        if expandsAParameterPack(declaredType) {
            let propertyName = pattern.identifier.text
            return .problem(
                CopyingDiagnostic.packExpansionPropertyType(propertyName: propertyName).diagnostic(at: declaredType)
            )
        }
        return .copyable(
            StoredProperty(
                name: pattern.identifier.text,
                argumentLabel: pattern.identifier.identifier?.name ?? pattern.identifier.text,
                type: declaredType.trimmed,
                accessLevel: accessLevel
            )
        )
    }

    /// Whether `type` expands a parameter pack anywhere within it.
    ///
    /// The `repeat` is looked for as a token rather than by walking for a pack
    /// expansion node, which keeps the check indifferent to where the expansion sits
    /// — a tuple element, a generic argument, a function parameter. `repeat` opens a
    /// loop everywhere else in the language, so in a type it can only be this.
    private static func expandsAParameterPack(_ type: TypeSyntax) -> Bool {
        type.tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.repeat) }
    }

    /// The type each binding of a declaration spells out, in order, with `nil` where
    /// the declaration leaves it to inference and the macro therefore cannot see it.
    ///
    /// A declaration may write one annotation once and share it across several
    /// bindings (`var x, y: Int` declares two `Int` properties). SwiftSyntax attaches
    /// that annotation only to the binding that carries it, so a binding without one
    /// takes the annotation of a later binding in the same declaration. Walking the
    /// bindings backwards carries that annotation to every binding it covers in one
    /// pass.
    ///
    /// The sharing stops at the first binding with an initial value, which types
    /// itself by inference instead: that is why Swift accepts `var x = 0, y: String`
    /// yet rejects `var x, y: Int = 0`.
    private static func declaredTypes(in bindings: PatternBindingListSyntax) -> [TypeSyntax?] {
        var types: [TypeSyntax?] = []
        var sharedType: TypeSyntax?

        for binding in bindings.reversed() {
            types.append(binding.typeAnnotation?.type ?? (binding.initializer == nil ? sharedType : nil))
            if binding.initializer != nil {
                sharedType = nil
            } else if let typeAnnotation = binding.typeAnnotation {
                sharedType = typeAnnotation.type
            }
        }
        return types.reversed()
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
