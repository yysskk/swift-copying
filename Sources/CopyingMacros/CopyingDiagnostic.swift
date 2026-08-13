import SwiftDiagnostics
import SwiftSyntax

extension MessageID {
    /// An identifier in the `CopyingMacros` domain, which every message the macro
    /// emits — diagnostics and Fix-Its alike — belongs to.
    static func copyingMacros(_ id: String) -> MessageID {
        MessageID(domain: "CopyingMacros", id: id)
    }
}

/// A diagnostic emitted while expanding the `@Copying` macro.
///
/// Each one carries a stable ``SwiftDiagnostics/MessageID``, a severity, and a
/// user-facing message, and is attached to the most relevant syntax node so the
/// compiler underlines the exact offending code.
///
/// Every problem the macro can detect for certain is an error. The three that turn
/// on code the macro cannot see are warnings: the two about the initializer,
/// because one declared in an extension or inherited from a superclass satisfies
/// the generated call while being invisible here, and the one about a subclassable
/// class, because a class that nothing subclasses copies itself correctly.
struct CopyingDiagnostic: DiagnosticMessage {
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
    let message: String

    private init(id: String, severity: DiagnosticSeverity, message: String) {
        self.diagnosticID = .copyingMacros(id)
        self.severity = severity
        self.message = message
    }

    /// The macro was attached to something other than a struct, class, or actor.
    static let unsupportedDeclaration = CopyingDiagnostic(
        id: "unsupportedDeclaration",
        severity: .error,
        message: "@Copying can only be applied to struct, class, or actor declarations"
    )

    /// The declaration has no stored property that can participate in a copy.
    static let noStoredProperties = CopyingDiagnostic(
        id: "noStoredProperties",
        severity: .error,
        message: "@Copying requires at least one stored property with an explicit type annotation"
    )

    /// A copyable stored property lacks the explicit type annotation the macro
    /// needs to spell out the corresponding `copying` parameter.
    static func missingTypeAnnotation(propertyName: String) -> CopyingDiagnostic {
        CopyingDiagnostic(
            id: "missingTypeAnnotation",
            severity: .error,
            message: "@Copying requires an explicit type annotation for '\(propertyName)'"
        )
    }

    /// A `var` binds several properties through a tuple pattern, which the macro
    /// cannot copy individually.
    static let tuplePatternBinding = CopyingDiagnostic(
        id: "tuplePatternBinding",
        severity: .error,
        message: "@Copying does not support tuple pattern bindings; declare each property separately"
    )

    /// A property a copy would have to carry is declared inside `#if`, so no single
    /// expansion can be right on every build configuration.
    ///
    /// This is an error rather than a warning, unlike the three below: no code the
    /// macro cannot see can make the expansion right. Carrying the property breaks
    /// the configurations where the branch is inactive, and leaving it out either
    /// fails to compile or, when the initializer defaults that parameter, silently
    /// resets the property on every copy.
    static let conditionalStoredProperty = CopyingDiagnostic(
        id: "conditionalStoredProperty",
        severity: .error,
        message:
            "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally"
    )

    /// The declaration does not declare an initializer that the generated `copying`
    /// method can call.
    static func missingInitializer(typeName: String, signature: String) -> CopyingDiagnostic {
        CopyingDiagnostic(
            id: "missingInitializer",
            severity: .warning,
            message:
                "@Copying requires '\(typeName)' to declare '\(signature)', which the generated 'copying' method calls"
        )
    }

    /// The declaration's initializer takes the copied properties but cannot be called
    /// the way the generated `copying` method calls it.
    static func unusableInitializer(signature: String) -> CopyingDiagnostic {
        CopyingDiagnostic(
            id: "unusableInitializer",
            severity: .warning,
            message:
                "@Copying calls '\(signature)' to build the copy, so it cannot be failable ('init?'), throwing, or async"
        )
    }

    /// The declaration is a `class` that can still be subclassed, so a subclass would
    /// inherit a `copying` that rebuilds only the superclass.
    static func subclassableClass(typeName: String) -> CopyingDiagnostic {
        CopyingDiagnostic(
            id: "subclassableClass",
            severity: .warning,
            message:
                "@Copying returns a new '\(typeName)' from 'copying', so a subclass inherits one that discards its own state; mark '\(typeName)' as 'final'"
        )
    }
}

extension CopyingDiagnostic {
    /// Builds a ``SwiftDiagnostics/Diagnostic`` for this message anchored to `node`,
    /// optionally offering `fixIts` that resolve it.
    func diagnostic(at node: some SyntaxProtocol, fixIts: [FixIt] = []) -> Diagnostic {
        Diagnostic(node: node, message: self, fixIts: fixIts)
    }

    /// Wraps this message in a ``SwiftDiagnostics/DiagnosticsError`` anchored to
    /// `node`, ready to be thrown from a macro expansion.
    func error(at node: some SyntaxProtocol) -> DiagnosticsError {
        DiagnosticsError(diagnostics: [diagnostic(at: node)])
    }
}
