import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// A property's name keeps its backticks wherever generated code refers to the
// property, but an argument label takes most names without them, and Swift warns
// about backticks a label does not need. These pin down which labels keep them.
@Suite("CopyingMacro Escaped Name Tests")
struct EscapedNameTests {
    @Test("Copying macro drops the backticks of an escaped identifier from its argument label")
    func copyingMacroWithEscapedIdentifier() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Menu {
                let `café`: String
            }
            """,
            expandedSource: """
                struct Menu {
                    let `café`: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - café: The new value for `café`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        `café`: String? = nil
                    ) -> Menu {
                        Menu(
                            café: `café` ?? self.`café`
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    // Raw identifiers (SE-0451) parse from swift-syntax 602 on; an older one splits
    // `the value` into separate tokens, so this only holds where the macro can see it.
    #if canImport(SwiftSyntax602)
        @Test("Copying macro keeps the backticks of a raw identifier in its argument label")
        func copyingMacroWithRawIdentifier() {
            assertMacroExpansionForTesting(
                """
                @Copying
                struct Reading {
                    var `the value`: Int
                }
                """,
                expandedSource: """
                    struct Reading {
                        var `the value`: Int

                        /// Creates a copy of this instance with the specified properties modified.
                        /// - Parameters:
                        ///   - the value: The new value for `the value`, or `nil` to keep the current value.
                        /// - Returns: A new instance with the specified modifications.
                        func copying(
                            `the value`: Int? = nil
                        ) -> Reading {
                            Reading(
                                `the value`: `the value` ?? self.`the value`
                            )
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    #endif

    @Test("Copying macro keeps the backticks of 'inout', the one keyword a label cannot be")
    func copyingMacroWithInoutPropertyName() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Parameter {
                var `inout`: Bool
            }
            """,
            expandedSource: """
                final class Parameter {
                    var `inout`: Bool

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - inout: The new value for `inout`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        `inout`: Bool? = nil
                    ) -> Parameter {
                        Parameter(
                            `inout`: `inout` ?? self.`inout`
                        )
                    }
                }
                """,
            // The signature in the message escapes the label the same way, which is how
            // Swift writes the compound name.
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Parameter' to declare 'init(`inout`:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(`inout`:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(`inout`:)'"],
            fixedSource: """
                @Copying
                final class Parameter {
                    var `inout`: Bool

                    init(`inout`: Bool) {
                        self.`inout` = `inout`
                    }
                }
                """
        )
    }
}
