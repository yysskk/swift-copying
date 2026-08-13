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

    @Test("Copying macro rejects an extension")
    func copyingMacroRejectsExtension() {
        assertMacroExpansionForTesting(
            """
            @Copying
            extension Point {
            }
            """,
            // An extension declares no stored property to copy, and the type it
            // extends is not the macro's to add members to.
            expandedSource: """
                extension Point {
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

    @Test("Copying macro rejects a property named after its type")
    func copyingMacroRejectsPropertyNamedAfterItsType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Money {
                let Money: Int
                let currency: String
            }
            """,
            // The call that builds the copy reads `Money(` as the parameter, not the
            // type: "cannot call value of non-function type 'Int?'".
            expandedSource: """
                struct Money {
                    let Money: Int
                    let currency: String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "propertyShadowsTypeName"),
                    message:
                        "@Copying cannot copy 'Money': the parameter it takes would shadow 'Money' in the call that builds the copy; rename the property",
                    line: 3,
                    column: 9
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects an escaped property named after its type")
    func copyingMacroRejectsEscapedPropertyNamedAfterItsType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct `default` {
                let `default`: Int
            }
            """,
            // Backticks escape an identifier rather than being part of it, so the two
            // names are the same one however each is spelled.
            expandedSource: """
                struct `default` {
                    let `default`: Int
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "propertyShadowsTypeName"),
                    message:
                        "@Copying cannot copy 'default': the parameter it takes would shadow 'default' in the call that builds the copy; rename the property",
                    line: 3,
                    column: 9
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects an opaque property type")
    func copyingMacroRejectsOpaquePropertyType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Provider {
                var single: some Equatable = 0
                var nested: [some Equatable] = [1]
            }
            """,
            // `some P` in parameter position declares a fresh generic parameter the
            // caller chooses, which is not the type the property holds.
            expandedSource: """
                struct Provider {
                    var single: some Equatable = 0
                    var nested: [some Equatable] = [1]
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "opaquePropertyType"),
                    message:
                        "@Copying cannot copy 'single': 'some' in the parameter it takes declares a new opaque type rather than the property's; declare the property with a concrete or 'any' type",
                    line: 3,
                    column: 17
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "opaquePropertyType"),
                    message:
                        "@Copying cannot copy 'nested': 'some' in the parameter it takes declares a new opaque type rather than the property's; declare the property with a concrete or 'any' type",
                    line: 4,
                    column: 17
                ),
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a property whose type expands a parameter pack")
    func copyingMacroRejectsPackExpansionPropertyType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Bundle<each T> {
                let label: String
                let values: (repeat each T)
            }
            """,
            expandedSource: """
                struct Bundle<each T> {
                    let label: String
                    let values: (repeat each T)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "packExpansionPropertyType"),
                    message:
                        "@Copying cannot copy 'values': 'copying' passes each property to an initializer, which Swift cannot do with a value that expands a parameter pack",
                    line: 4,
                    column: 17
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a pack expansion nested in a property's type")
    func copyingMacroRejectsNestedPackExpansionPropertyType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Bundle<each T> {
                let build: (repeat each T) -> String
            }
            """,
            expandedSource: """
                struct Bundle<each T> {
                    let build: (repeat each T) -> String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "packExpansionPropertyType"),
                    message:
                        "@Copying cannot copy 'build': 'copying' passes each property to an initializer, which Swift cannot do with a value that expands a parameter pack",
                    line: 3,
                    column: 16
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a stored property declared inside #if")
    func copyingMacroRejectsConditionalStoredProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Settings {
                var name: String
                #if DEBUG
                var verbose: Bool
                #endif
            }
            """,
            expandedSource: """
                struct Settings {
                    var name: String
                    #if DEBUG
                    var verbose: Bool
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "conditionalStoredProperty"),
                    message:
                        "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally",
                    line: 5,
                    column: 9
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro rejects a conditional stored property in every clause")
    func copyingMacroRejectsConditionalStoredPropertiesInEveryClause() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Layout {
                var title: String
                #if os(iOS)
                var inset: Double
                #else
                var margin: Double
                #if DEBUG
                var trace: Bool
                #endif
                #endif
            }
            """,
            // `#elseif`, `#else`, and a nested directive contribute properties on their
            // own configurations, so each is reported.
            expandedSource: """
                struct Layout {
                    var title: String
                    #if os(iOS)
                    var inset: Double
                    #else
                    var margin: Double
                    #if DEBUG
                    var trace: Bool
                    #endif
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "conditionalStoredProperty"),
                    message:
                        "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally",
                    line: 5,
                    column: 9
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "conditionalStoredProperty"),
                    message:
                        "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally",
                    line: 7,
                    column: 9
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "conditionalStoredProperty"),
                    message:
                        "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally",
                    line: 9,
                    column: 9
                ),
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
                #if DEBUG
                var verbose: Bool
                #endif
            }
            """,
            expandedSource: """
                struct Broken {
                    var count = 0
                    var (x, y) = (0, 0)
                    #if DEBUG
                    var verbose: Bool
                    #endif
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
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "conditionalStoredProperty"),
                    message:
                        "@Copying does not support a stored property declared inside '#if'; declare the property unconditionally",
                    line: 6,
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
