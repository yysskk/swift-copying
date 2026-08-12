import SwiftDiagnostics

/// A Fix-It offered alongside a diagnostic from the `@Copying` macro.
///
/// Each one carries a stable ``SwiftDiagnostics/MessageID`` and the label an editor
/// puts on the button that applies the change.
struct CopyingFixItMessage: FixItMessage {
    let fixItID: MessageID
    let message: String

    private init(id: String, message: String) {
        self.fixItID = .copyingMacros(id)
        self.message = message
    }

    /// Write the initializer the generated `copying` method calls into the declaration.
    static func insertInitializer(signature: String) -> CopyingFixItMessage {
        CopyingFixItMessage(id: "insertInitializer", message: "Add '\(signature)'")
    }

    /// Mark the class `final`, so no subclass can inherit the generated method.
    static func markFinal(typeName: String) -> CopyingFixItMessage {
        CopyingFixItMessage(id: "markFinal", message: "Mark '\(typeName)' as 'final'")
    }
}
