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
        }
    }

    var severity: DiagnosticSeverity { .error }

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
