import SwiftDiagnostics
import SwiftSyntax

/// A diagnostic emitted while expanding the `@Copying` macro.
///
/// Each case carries a stable ``SwiftDiagnostics/MessageID`` (in the
/// `CopyingMacros` domain) and a user-facing message, and is attached to the most
/// relevant syntax node so the compiler underlines the exact offending code.
enum CopyingDiagnostic: DiagnosticMessage {
    /// The macro was attached to something other than a struct, class, or actor.
    case unsupportedDeclaration
    /// The declaration has no stored property that can participate in a copy.
    case noStoredProperties
    /// A copyable stored property lacks the explicit type annotation the macro
    /// needs to spell out the corresponding `copying` parameter.
    case missingTypeAnnotation(propertyName: String)
    /// A `var` binds several properties through a tuple pattern, which the macro
    /// cannot copy individually.
    case tuplePatternBinding
    /// The declaration does not declare an initializer that the generated `copying`
    /// method can call.
    case missingInitializer(typeName: String, signature: String)
    /// The declaration's initializer takes the copied properties but cannot be called
    /// the way the generated `copying` method calls it.
    case unusableInitializer(signature: String)

    var message: String {
        switch self {
        case .unsupportedDeclaration:
            return "@Copying can only be applied to struct, class, or actor declarations"
        case .noStoredProperties:
            return "@Copying requires at least one stored property with an explicit type annotation"
        case .missingTypeAnnotation(let propertyName):
            return "@Copying requires an explicit type annotation for '\(propertyName)'"
        case .tuplePatternBinding:
            return "@Copying does not support tuple pattern bindings; declare each property separately"
        case .missingInitializer(let typeName, let signature):
            return
                "@Copying requires '\(typeName)' to declare '\(signature)', which the generated 'copying' method calls"
        case .unusableInitializer(let signature):
            return
                "@Copying calls '\(signature)' to build the copy, so it cannot be failable ('init?'), throwing, or async"
        }
    }

    /// Every problem the macro can detect for certain is an error. The two about the
    /// initializer are the exception: an initializer declared in an extension or
    /// inherited from a superclass satisfies the generated call but is invisible to a
    /// macro, so flagging one as an error would reject code that compiles.
    var severity: DiagnosticSeverity {
        switch self {
        case .unsupportedDeclaration, .noStoredProperties, .missingTypeAnnotation, .tuplePatternBinding:
            return .error
        case .missingInitializer, .unusableInitializer:
            return .warning
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "CopyingMacros", id: identifier)
    }

    /// The stable identifier for this message within the `CopyingMacros` domain.
    private var identifier: String {
        switch self {
        case .unsupportedDeclaration:
            return "unsupportedDeclaration"
        case .noStoredProperties:
            return "noStoredProperties"
        case .missingTypeAnnotation:
            return "missingTypeAnnotation"
        case .tuplePatternBinding:
            return "tuplePatternBinding"
        case .missingInitializer:
            return "missingInitializer"
        case .unusableInitializer:
            return "unusableInitializer"
        }
    }
}

extension CopyingDiagnostic {
    /// Builds a ``SwiftDiagnostics/Diagnostic`` for this message anchored to `node`.
    func diagnostic(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: node, message: self)
    }

    /// Wraps this message in a ``SwiftDiagnostics/DiagnosticsError`` anchored to
    /// `node`, ready to be thrown from a macro expansion.
    func error(at node: some SyntaxProtocol) -> DiagnosticsError {
        DiagnosticsError(diagnostics: [diagnostic(at: node)])
    }
}
