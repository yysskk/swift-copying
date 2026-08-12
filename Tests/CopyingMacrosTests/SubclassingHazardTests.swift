import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Subclassing Hazard Tests")
struct SubclassingHazardTests {
    @Test("Copying macro warns when a class is not final")
    func copyingMacroWarnsWhenClassIsNotFinal() {
        assertMacroExpansionForTesting(
            """
            @Copying
            class User {
                let id: Int

                init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                class User {
                    let id: Int

                    init(id: Int) {
                        self.id = id
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (Int)? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'User' from 'copying', so a subclass inherits one that discards its own state; mark 'User' as 'final'",
                    line: 2,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'User' as 'final'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Mark 'User' as 'final'"],
            fixedSource: """
                @Copying
                final class User {
                    let id: Int

                    init(id: Int) {
                        self.id = id
                    }
                }
                """
        )
    }

    @Test("Copying macro Fix-It marking a class final keeps the modifiers it already has")
    func copyingMacroFixItKeepsExistingModifiersWhenMarkingFinal() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public class User {
                let id: Int

                public init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                public class User {
                    let id: Int

                    public init(id: Int) {
                        self.id = id
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        id: (Int)? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'User' from 'copying', so a subclass inherits one that discards its own state; mark 'User' as 'final'",
                    line: 2,
                    column: 8,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'User' as 'final'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Mark 'User' as 'final'"],
            fixedSource: """
                @Copying
                public final class User {
                    let id: Int

                    public init(id: Int) {
                        self.id = id
                    }
                }
                """
        )
    }

    @Test("Copying macro Fix-It marking an open class final demotes it to public")
    func copyingMacroFixItDemotesOpenClassWhenMarkingFinal() {
        assertMacroExpansionForTesting(
            """
            @Copying
            open class User {
                let id: Int

                public init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                open class User {
                    let id: Int

                    public init(id: Int) {
                        self.id = id
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        id: (Int)? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'User' from 'copying', so a subclass inherits one that discards its own state; mark 'User' as 'final'",
                    line: 2,
                    column: 6,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'User' as 'final'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Mark 'User' as 'final'"],
            // `open` and `final` contradict each other, so it becomes `public`, which
            // keeps the class visible everywhere it was.
            fixedSource: """
                @Copying
                public final class User {
                    let id: Int

                    public init(id: Int) {
                        self.id = id
                    }
                }
                """
        )
    }

    @Test("Copying macro Fix-It marking a class final follows the indentation of a nested type")
    func copyingMacroFixItFollowsNestedIndentationWhenMarkingFinal() {
        assertMacroExpansionForTesting(
            """
            enum Namespace {
                @Copying
                class Box {
                    let value: Int

                    init(value: Int) {
                        self.value = value
                    }
                }
            }
            """,
            expandedSource: """
                enum Namespace {
                    class Box {
                        let value: Int

                        init(value: Int) {
                            self.value = value
                        }

                        /// Creates a copy of this instance with the specified properties modified.
                        /// - Parameters:
                        ///   - value: The new value for `value`, or `nil` to keep the current value.
                        /// - Returns: A new instance with the specified modifications.
                        func copying(
                            value: (Int)? = nil
                        ) -> Box {
                            Box(
                                value: value ?? self.value
                            )
                        }
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'Box' from 'copying', so a subclass inherits one that discards its own state; mark 'Box' as 'final'",
                    line: 3,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'Box' as 'final'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Mark 'Box' as 'final'"],
            fixedSource: """
                enum Namespace {
                    @Copying
                    final class Box {
                        let value: Int

                        init(value: Int) {
                            self.value = value
                        }
                    }
                }
                """
        )
    }

    @Test("Copying macro reports both the missing final and the missing initializer")
    func copyingMacroReportsSubclassableClassAndMissingInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            class User {
                var id: Int = 0
            }
            """,
            expandedSource: """
                class User {
                    var id: Int = 0

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (Int)? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'User' from 'copying', so a subclass inherits one that discards its own state; mark 'User' as 'final'",
                    line: 2,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'User' as 'final'")]
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'User' to declare 'init(id:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(id:)'")]
                ),
            ],
            macros: testMacros
        )
    }
}
