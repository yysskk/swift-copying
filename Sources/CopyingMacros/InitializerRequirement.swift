import SwiftSyntax

/// The initializer that the generated `copying` method calls to build the copy.
///
/// `copying` constructs the new instance with `TypeName(label: value, …)`, passing
/// every copyable stored property's name as an argument label. This type models that
/// call so the macro can check the annotated declaration for an initializer able to
/// accept it, and name the exact signature the declaration is missing.
struct InitializerRequirement {
    /// The argument labels the generated call passes, in order.
    private let argumentLabels: [String]

    /// Creates the requirement implied by the properties the copy has to pass on.
    init(storedProperties: [StoredProperty]) {
        argumentLabels = storedProperties.map(\.name)
    }

    /// The required initializer spelled the way Swift writes a compound name,
    /// e.g. `init(id:username:isActive:)`.
    var signature: String {
        "init(\(argumentLabels.map { "\($0):" }.joined()))"
    }

    /// What keeps `declaration` from supplying the initializer the copy needs, or `nil`
    /// when it supplies one.
    ///
    /// A `struct` that declares no initializer of its own falls short of nothing: Swift
    /// synthesizes a memberwise initializer whose parameters are exactly the properties
    /// the macro copies. Declaring any initializer inside the `struct` body suppresses
    /// that synthesis, and a `class` or `actor` never gets one, so those must offer a
    /// usable initializer themselves.
    ///
    /// Only the annotated declaration is inspected, which is all a macro can see. An
    /// initializer added in an extension or inherited from a superclass also satisfies
    /// the call, so ``Shortfall/noInitializer`` means "none is visible here" rather than
    /// "the copy cannot be built" — hence the warning in ``CopyingDiagnostic``.
    func shortfall(of declaration: some DeclGroupSyntax) -> Shortfall? {
        let initializers = declaration.memberBlock.members.compactMap {
            $0.decl.as(InitializerDeclSyntax.self)
        }
        guard !initializers.isEmpty else {
            return declaration.is(StructDeclSyntax.self) ? nil : .noInitializer
        }
        if initializers.contains(where: { acceptsArguments($0) && $0.isCallableAsPlainExpression }) {
            return nil
        }
        // Singling out an initializer that takes the right arguments but cannot be
        // called plainly gives a far better diagnostic than "declare this signature",
        // which the author plainly tried to do.
        if let unusable = initializers.first(where: acceptsArguments) {
            return .unusableInitializer(unusable)
        }
        return .noInitializer
    }

    /// Whether a call passing these argument labels resolves to `initializer`.
    ///
    /// Swift matches arguments to parameters in declaration order and lets a call leave
    /// a parameter out only when it is omittable. The labels must therefore appear in
    /// order among the parameters, and every parameter they skip past must be
    /// omittable. Parameter types are not compared: a macro sees only how a type is
    /// spelled, so `Int` and a typealias for it would look like a mismatch.
    private func acceptsArguments(_ initializer: InitializerDeclSyntax) -> Bool {
        var labels = argumentLabels[...]
        for parameter in initializer.signature.parameterClause.parameters {
            if let label = labels.first, parameter.argumentLabel == label {
                labels.removeFirst()
            } else if !parameter.isOmittable {
                return false
            }
        }
        return labels.isEmpty
    }
}

extension InitializerRequirement {
    /// What keeps a declaration from supplying the initializer the copy needs.
    enum Shortfall {
        /// No initializer that takes the copied properties is visible on the
        /// declaration.
        case noInitializer
        /// An initializer takes the copied properties but cannot be called the way
        /// `copying` calls it.
        case unusableInitializer(InitializerDeclSyntax)
    }
}

extension InitializerDeclSyntax {
    /// Whether `Type(…)` on its own can call this initializer.
    ///
    /// `copying` builds the copy with a plain call and returns the result as the type
    /// itself, so an initializer it calls cannot be failable (the call would produce an
    /// optional), throwing (it would need `try`), or `async` (it would need `await`).
    fileprivate var isCallableAsPlainExpression: Bool {
        guard optionalMark == nil else {
            return false
        }
        guard let effectSpecifiers = signature.effectSpecifiers else {
            return true
        }
        return effectSpecifiers.asyncSpecifier == nil && effectSpecifiers.throwsClause == nil
    }
}

extension FunctionParameterSyntax {
    /// The label a caller writes for this parameter, or `nil` when it takes an
    /// unlabelled argument (`_ value: Int`) and so cannot match a labelled one.
    fileprivate var argumentLabel: String? {
        firstName.tokenKind == .wildcard ? nil : firstName.text
    }

    /// Whether a call may leave this parameter out, which Swift allows for a parameter
    /// with a default value and for a variadic one.
    fileprivate var isOmittable: Bool {
        defaultValue != nil || ellipsis != nil
    }
}
