import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Diagnostic Tests")
struct DiagnosticTests {
    @Test("Copying macro requires an explicit type annotation")
    func copyingMacroRequiresTypeAnnotation() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Counter {
                var count = 0
            }
            """,
            expandedSource: """
                struct Counter {
                    var count = 0
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingTypeAnnotation"),
                    message: "@Copying requires an explicit type annotation for 'count'",
                    line: 3,
                    column: 9
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects declarations other than struct, class, or actor")
    func copyingMacroRejectsUnsupportedDeclaration() {
        assertMacroExpansionForTesting(
            """
            @Copying
            enum Direction {
                case north
            }
            """,
            expandedSource: """
                enum Direction {
                    case north
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unsupportedDeclaration"),
                    message: "@Copying can only be applied to struct, class, or actor declarations",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a type without stored properties")
    func copyingMacroRejectsTypeWithoutStoredProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Empty {
            }
            """,
            expandedSource: """
                struct Empty {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "noStoredProperties"),
                    message: "@Copying requires at least one stored property with an explicit type annotation",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects tuple pattern bindings")
    func copyingMacroRejectsTuplePatternBinding() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Point {
                var (x, y) = (0, 0)
            }
            """,
            expandedSource: """
                struct Point {
                    var (x, y) = (0, 0)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "tuplePatternBinding"),
                    message: "@Copying does not support tuple pattern bindings; declare each property separately",
                    line: 3,
                    column: 9
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro reports every offending property in one expansion")
    func copyingMacroReportsMultipleViolationsTogether() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Broken {
                var count = 0
                var (x, y) = (0, 0)
            }
            """,
            expandedSource: """
                struct Broken {
                    var count = 0
                    var (x, y) = (0, 0)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingTypeAnnotation"),
                    message: "@Copying requires an explicit type annotation for 'count'",
                    line: 3,
                    column: 9
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "tuplePatternBinding"),
                    message: "@Copying does not support tuple pattern bindings; declare each property separately",
                    line: 4,
                    column: 9
                ),
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a type whose only members are static or computed")
    func copyingMacroRejectsTypeWithNoCopyableProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Configuration {
                static let key: String = "default"
                var isEmpty: Bool {
                    true
                }
            }
            """,
            expandedSource: """
                struct Configuration {
                    static let key: String = "default"
                    var isEmpty: Bool {
                        true
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "noStoredProperties"),
                    message: "@Copying requires at least one stored property with an explicit type annotation",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a protocol declaration")
    func copyingMacroRejectsProtocol() {
        assertMacroExpansionForTesting(
            """
            @Copying
            protocol Named {
                var name: String { get }
            }
            """,
            expandedSource: """
                protocol Named {
                    var name: String { get }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unsupportedDeclaration"),
                    message: "@Copying can only be applied to struct, class, or actor declarations",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

}
