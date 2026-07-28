import SwiftDiagnostics

/// A Fix-It offered alongside a diagnostic from the `@Copying` macro.
///
/// Each case carries a stable ``SwiftDiagnostics/MessageID`` (in the `CopyingMacros`
/// domain) and the label an editor puts on the button that applies the change.
enum CopyingFixItMessage: FixItMessage {
    /// Write the initializer the generated `copying` method calls into the declaration.
    case insertInitializer(signature: String)
    /// Mark the class `final`, so no subclass can inherit the generated method.
    case markFinal(typeName: String)

    var message: String {
        switch self {
        case .insertInitializer(let signature):
            return "Add '\(signature)'"
        case .markFinal(let typeName):
            return "Mark '\(typeName)' as 'final'"
        }
    }

    var fixItID: MessageID {
        switch self {
        case .insertInitializer:
            return MessageID(domain: "CopyingMacros", id: "insertInitializer")
        case .markFinal:
            return MessageID(domain: "CopyingMacros", id: "markFinal")
        }
    }
}
