import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler plugin entry point that exposes every macro in this module to
/// the Swift compiler.
@main
struct CopyingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyingMacro.self
    ]
}
