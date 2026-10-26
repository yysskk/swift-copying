import SwiftDiagnostics
import SwiftSyntax

/// The actor isolation the macro gives the `copying` method it generates.
///
/// The method normally takes the isolation of the type it is declared in, which is
/// what a member does without an attribute of its own. That is not enough when a
/// copied property is isolated to the main actor while the type is not: the method
/// reads every copied property synchronously, and Swift rejects reading a
/// main-actor-isolated property from a `class` or `actor` method that is not
/// isolated to the main actor too.
enum MethodIsolation {
    /// The method carries no attribute and takes the isolation of its type.
    case inherited
    /// The method is marked `@MainActor`.
    case mainActor
}

extension MethodIsolation {
    /// The isolation for the `copying` method of `declaration`, which copies
    /// `storedProperties`.
    ///
    /// Only a `class` or an `actor` needs the method on the main actor. A `struct` can
    /// read its own main-actor-isolated stored property from a method with no
    /// isolation (SE-0434), so marking the method there would only restrict where it
    /// can be called. A type that is itself marked `@MainActor` already hands its
    /// isolation to the method, so the attribute would only repeat it.
    ///
    /// Only `@MainActor` is recognized. A custom global actor, such as `@DataActor`,
    /// reads exactly like a property wrapper attribute, and which of the two an
    /// attribute names is decided by a declaration a macro cannot see.
    ///
    /// - Throws: A ``SwiftDiagnostics/DiagnosticsError`` when `declaration` is an
    ///   actor that copies a main-actor property alongside a mutable property of its
    ///   own. The method would have to be isolated to the main actor to read the one
    ///   and to the actor to read the other, and a method is isolated to one actor at
    ///   most, so every such property of the actor's is reported.
    init(
        forMethodOf declaration: some DeclGroupSyntax,
        copying storedProperties: [StoredProperty]
    ) throws {
        let isReferenceType = declaration.is(ClassDeclSyntax.self) || declaration.is(ActorDeclSyntax.self)
        guard isReferenceType,
            !declaration.attributes.containsMainActor,
            let mainActorProperty = storedProperties.first(where: { $0.isolation == .mainActor })
        else {
            self = .inherited
            return
        }

        // A `let` is left alone: an actor's constant of a `Sendable` type can be read
        // from the main actor, and whether a type is `Sendable` is not something its
        // spelling says. A `var` of the actor's own can only ever be read on the actor.
        let actorIsolatedProperties =
            declaration.is(ActorDeclSyntax.self)
            ? storedProperties.filter { $0.isolation == .inherited && $0.isMutable } : []
        guard actorIsolatedProperties.isEmpty else {
            throw DiagnosticsError(
                diagnostics: actorIsolatedProperties.map { property in
                    CopyingDiagnostic
                        .mixedActorIsolation(
                            propertyName: property.argumentLabel,
                            mainActorPropertyName: mainActorProperty.argumentLabel
                        )
                        .diagnostic(at: property.binding)
                }
            )
        }
        self = .mainActor
    }

    /// The attribute generated code spells for this isolation, with the trailing space
    /// that separates it from what follows.
    ///
    /// `inherited` renders as nothing, which is how a member takes its type's
    /// isolation.
    var rendered: String {
        switch self {
        case .inherited:
            return ""
        case .mainActor:
            return "@MainActor "
        }
    }
}

extension AttributeListSyntax {
    /// Whether the list contains `@MainActor`, spelled on its own or qualified with
    /// the module that declares it.
    ///
    /// An attribute inside `#if` is not considered, since a macro cannot know which
    /// branch a build takes.
    var containsMainActor: Bool {
        contains { element in
            guard case .attribute(let attribute) = element else {
                return false
            }
            switch attribute.attributeName.trimmedDescription {
            case "MainActor", "_Concurrency.MainActor":
                return true
            default:
                return false
            }
        }
    }
}
