import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Access Level Tests")
struct AccessLevelTests {
    @Test("Copying macro inherits public access level")
    func copyingMacroWithPublicStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Person {
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
                public struct Person {
                    let name: String
                    let age: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - age: The new value for `age`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        name: (String)? = nil,
                        age: (Int)? = nil
                    ) -> Person {
                        Person(
                            name: name ?? self.name,
                            age: age ?? self.age
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro inherits package access level")
    func copyingMacroWithPackageStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            package struct Person {
                let name: String
            }
            """,
            expandedSource: """
                package struct Person {
                    let name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    package func copying(
                        name: (String)? = nil
                    ) -> Person {
                        Person(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro maps private to fileprivate")
    func copyingMacroWithPrivateStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            private struct Person {
                let name: String
            }
            """,
            expandedSource: """
                private struct Person {
                    let name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    fileprivate func copying(
                        name: (String)? = nil
                    ) -> Person {
                        Person(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro inherits fileprivate access level")
    func copyingMacroWithFileprivateStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            fileprivate struct Person {
                let name: String
            }
            """,
            expandedSource: """
                fileprivate struct Person {
                    let name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    fileprivate func copying(
                        name: (String)? = nil
                    ) -> Person {
                        Person(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro maps open to public")
    func copyingMacroWithOpenClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            open class User {
                let id: Int
                var username: String

                public init(id: Int, username: String) {
                    self.id = id
                    self.username = username
                }
            }
            """,
            expandedSource: """
                open class User {
                    let id: Int
                    var username: String

                    public init(id: Int, username: String) {
                        self.id = id
                        self.username = username
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - username: The new value for `username`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        id: (Int)? = nil,
                        username: (String)? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id,
                            username: username ?? self.username
                        )
                    }
                }
                """,
            // An `open` class is subclassable by definition, so the warning about that
            // comes along; the Fix-It it carries is exercised separately.
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
            macros: testMacros
        )
    }

    @Test("Copying macro picks access level among multiple modifiers")
    func copyingMacroWithPublicFinalClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public final class User {
                let id: Int

                public init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                public final class User {
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
            macros: testMacros
        )
    }

    @Test("Copying macro inherits an explicit internal access level")
    func copyingMacroWithInternalStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            internal struct Person {
                let name: String
            }
            """,
            expandedSource: """
                internal struct Person {
                    let name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    internal func copying(
                        name: (String)? = nil
                    ) -> Person {
                        Person(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

}
