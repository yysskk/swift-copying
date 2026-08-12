import CopyingMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

let testMacros: [String: Macro.Type] = [
    "Copying": CopyingMacro.self
]

/// Expands `originalSource` and checks the result against `expandedSource`, the
/// expected `diagnostics`, and — when `applyFixIts` names some — the `fixedSource`
/// applying them produces.
///
/// swift-syntax's `assertMacroExpansion` is written against no particular test
/// framework: it reports through a closure instead of failing a test itself. This
/// wrapper hands it one that records an issue with swift-testing, attributed to the
/// calling test rather than to this file.
///
/// - Parameters:
///   - originalSource: The source to expand, with the macro attached.
///   - expandedSource: The source the expansion is expected to produce.
///   - diagnostics: The diagnostics the expansion is expected to emit, in order.
///   - macros: The macros available to the expansion, by attribute name.
///   - applyFixIts: The Fix-It messages to apply, or `nil` to apply none.
///   - fixedSource: The source applying `applyFixIts` is expected to produce.
func assertMacroExpansionForTesting(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource: String? = nil,
    fileID: StaticString = #fileID, filePath: StaticString = #filePath,
    line: UInt = #line, column: UInt = #column
) {
    assertMacroExpansion(
        originalSource, expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: macros.mapValues { MacroSpec(type: $0) },
        applyFixIts: applyFixIts,
        fixedSource: fixedSource,
        indentationWidth: .spaces(4)
    ) { spec in
        Issue.record(
            .init(rawValue: spec.message),
            sourceLocation: .init(
                fileID: String(describing: fileID), filePath: String(describing: filePath),
                line: Int(line), column: Int(column)
            )
        )
    }
}
