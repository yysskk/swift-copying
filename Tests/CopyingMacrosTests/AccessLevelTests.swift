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
                public let name: String
                public let age: Int
            }
            """,
            expandedSource: """
                public struct Person {
                    public let name: String
                    public let age: Int

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
                package let name: String
            }
            """,
            expandedSource: """
                package struct Person {
                    package let name: String

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
                public let id: Int
                public var username: String

                public init(id: Int, username: String) {
                    self.id = id
                    self.username = username
                }
            }
            """,
            expandedSource: """
                open class User {
                    public let id: Int
                    public var username: String

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
                public let id: Int

                public init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                public final class User {
                    public let id: Int

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

    @Test("Copying macro writes an internal access level implicitly")
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
                    func copying(
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

    @Test("Copying macro caps a public type at an internal property")
    func copyingMacroCapsPublicTypeAtInternalProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Session {
                public let id: String
                let token: Token
            }
            """,
            // A `public` method taking an `internal` type does not compile at all
            // ("method cannot be declared public because its parameter uses an
            // internal type"), which capping at the property avoids.
            expandedSource: """
                public struct Session {
                    public let id: String
                    let token: Token

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - token: The new value for `token`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (String)? = nil,
                        token: (Token)? = nil
                    ) -> Session {
                        Session(
                            id: id ?? self.id,
                            token: token ?? self.token
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro caps a public type at a private property")
    func copyingMacroCapsPublicTypeAtPrivateProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Session {
                public let id: String
                private var token: String
            }
            """,
            // `private` rather than `fileprivate`: the method sits inside the type
            // declaration, which is as far as a `private` property reaches.
            expandedSource: """
                public struct Session {
                    public let id: String
                    private var token: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - token: The new value for `token`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    private func copying(
                        id: (String)? = nil,
                        token: (String)? = nil
                    ) -> Session {
                        Session(
                            id: id ?? self.id,
                            token: token ?? self.token
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro caps a public type at a package property")
    func copyingMacroCapsPublicTypeAtPackageProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Region {
                public let id: Int
                package let code: String
            }
            """,
            expandedSource: """
                public struct Region {
                    public let id: Int
                    package let code: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - code: The new value for `code`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    package func copying(
                        id: (Int)? = nil,
                        code: (String)? = nil
                    ) -> Region {
                        Region(
                            id: id ?? self.id,
                            code: code ?? self.code
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro keeps a private property private in a private type")
    func copyingMacroKeepsPrivatePropertyPrivateInPrivateType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            private struct Vault {
                private var combination: Int
            }
            """,
            expandedSource: """
                private struct Vault {
                    private var combination: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - combination: The new value for `combination`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    private func copying(
                        combination: (Int)? = nil
                    ) -> Vault {
                        Vault(
                            combination: combination ?? self.combination
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro ignores a setter-only access modifier")
    func copyingMacroIgnoresSetterAccessModifier() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Scoreboard {
                public private(set) var score: Int
            }
            """,
            // `private(set)` constrains the setter; `copying` reads the property and
            // builds a new instance, so the public read access governs.
            expandedSource: """
                public struct Scoreboard {
                    public private(set) var score: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - score: The new value for `score`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        score: (Int)? = nil
                    ) -> Scoreboard {
                        Scoreboard(
                            score: score ?? self.score
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro reads a lone setter-only modifier as internal")
    func copyingMacroReadsSetterOnlyModifierAsInternal() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Profile {
                private(set) var name: String
            }
            """,
            expandedSource: """
                struct Profile {
                    private(set) var name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil
                    ) -> Profile {
                        Profile(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro treats an open property as public")
    func copyingMacroTreatsOpenPropertyAsPublic() {
        assertMacroExpansionForTesting(
            """
            @Copying
            open class Theme {
                open var name: String

                public init(name: String) {
                    self.name = name
                }
            }
            """,
            expandedSource: """
                open class Theme {
                    open var name: String

                    public init(name: String) {
                        self.name = name
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        name: (String)? = nil
                    ) -> Theme {
                        Theme(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "subclassableClass"),
                    message:
                        "@Copying returns a new 'Theme' from 'copying', so a subclass inherits one that discards its own state; mark 'Theme' as 'final'",
                    line: 2,
                    column: 6,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Mark 'Theme' as 'final'")]
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro caps only at the properties it copies")
    func copyingMacroIgnoresNonCopyablePropertiesWhenCapping() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Gauge {
                public var value: Int
                private static let scale: Int = 10
                private let ceiling: Int = 100
                private var doubled: Int {
                    value * 2
                }
            }
            """,
            // None of the three `private` members takes part in a copy, so none of
            // them limits who can make one.
            expandedSource: """
                public struct Gauge {
                    public var value: Int
                    private static let scale: Int = 10
                    private let ceiling: Int = 100
                    private var doubled: Int {
                        value * 2
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
                        value: (Int)? = nil
                    ) -> Gauge {
                        Gauge(
                            value: value ?? self.value
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro applies a declaration's access level to each of its bindings")
    func copyingMacroAppliesDeclarationAccessToEveryBinding() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public struct Size {
                private let width, height: Int
            }
            """,
            expandedSource: """
                public struct Size {
                    private let width, height: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - width: The new value for `width`, or `nil` to keep the current value.
                    ///   - height: The new value for `height`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    private func copying(
                        width: (Int)? = nil,
                        height: (Int)? = nil
                    ) -> Size {
                        Size(
                            width: width ?? self.width,
                            height: height ?? self.height
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

}
