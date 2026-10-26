import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Isolation Tests")
struct IsolationTests {
    @Test("Copying macro isolates the method of a class with a main-actor property")
    func copyingMacroWithMainActorPropertyInClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Model {
                @MainActor var title: String
                let id: Int

                init(title: String, id: Int) {
                    self.title = title
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class Model {
                    @MainActor var title: String
                    let id: Int

                    init(title: String, id: Int) {
                        self.title = title
                        self.id = id
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor func copying(
                        title: (String)? = nil,
                        id: (Int)? = nil
                    ) -> Model {
                        Model(
                            title: title ?? self.title,
                            id: id ?? self.id
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro isolates the method of an actor with a main-actor property")
    func copyingMacroWithMainActorPropertyInActor() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Session {
                @MainActor var title: String

                init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                actor Session {
                    @MainActor var title: String

                    init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor func copying(
                        title: (String)? = nil
                    ) -> Session {
                        Session(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro places the isolation before the access level")
    func copyingMacroWithMainActorPropertyInPublicClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public final class Model {
                @MainActor public var title: String

                public init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                public final class Model {
                    @MainActor public var title: String

                    public init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor public func copying(
                        title: (String)? = nil
                    ) -> Model {
                        Model(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro recognizes a module-qualified main-actor attribute")
    func copyingMacroWithQualifiedMainActorProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Model {
                @_Concurrency.MainActor var title: String

                init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                final class Model {
                    @_Concurrency.MainActor var title: String

                    init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor func copying(
                        title: (String)? = nil
                    ) -> Model {
                        Model(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro leaves the method of a struct with a main-actor property unisolated")
    func copyingMacroWithMainActorPropertyInStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Label {
                @MainActor var text: String
            }
            """,
            expandedSource: """
                struct Label {
                    @MainActor var text: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - text: The new value for `text`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        text: (String)? = nil
                    ) -> Label {
                        Label(
                            text: text ?? self.text
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro does not repeat the isolation of a main-actor class")
    func copyingMacroWithMainActorClass() {
        assertMacroExpansionForTesting(
            """
            @MainActor
            @Copying
            final class Model {
                @MainActor var title: String

                init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                @MainActor
                final class Model {
                    @MainActor var title: String

                    init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: (String)? = nil
                    ) -> Model {
                        Model(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro ignores a main-actor property the copy does not carry")
    func copyingMacroWithUncopiedMainActorProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Model {
                @MainActor static var shared: Int = 0
                @MainActor var summary: String { "" }
                let id: Int

                init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class Model {
                    @MainActor static var shared: Int = 0
                    @MainActor var summary: String { "" }
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
                    ) -> Model {
                        Model(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro does not mistake a custom attribute for main-actor isolation")
    func copyingMacroWithCustomAttributeProperty() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Model {
                @Published var title: String

                init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                final class Model {
                    @Published var title: String

                    init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: (String)? = nil
                    ) -> Model {
                        Model(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }
}
