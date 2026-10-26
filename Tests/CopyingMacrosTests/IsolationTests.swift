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

    @Test("Copying macro rejects an actor that copies its own mutable property alongside a main-actor one")
    func copyingMacroRejectsMixedActorIsolation() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Session {
                @MainActor var title: String
                var count: Int
                var `default`: Bool

                init(title: String, count: Int, default: Bool) {
                    self.title = title
                    self.count = count
                    self.default = `default`
                }
            }
            """,
            expandedSource: """
                actor Session {
                    @MainActor var title: String
                    var count: Int
                    var `default`: Bool

                    init(title: String, count: Int, default: Bool) {
                        self.title = title
                        self.count = count
                        self.default = `default`
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "mixedActorIsolation"),
                    message:
                        "@Copying cannot copy 'count' alongside main-actor property 'title': 'copying' would have to be isolated to both the actor and the main actor; move the main-actor state out of the actor",
                    line: 4,
                    column: 9
                ),
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "mixedActorIsolation"),
                    message:
                        "@Copying cannot copy 'default' alongside main-actor property 'title': 'copying' would have to be isolated to both the actor and the main actor; move the main-actor state out of the actor",
                    line: 5,
                    column: 9
                ),
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro isolates the method of an actor whose own copied state the main actor can read")
    func copyingMacroWithMainActorPropertyAndReadableActorState() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Session {
                @MainActor var title: String
                let id: Int
                nonisolated(unsafe) var hits: Int

                init(title: String, id: Int, hits: Int) {
                    self.title = title
                    self.id = id
                    self.hits = hits
                }
            }
            """,
            expandedSource: """
                actor Session {
                    @MainActor var title: String
                    let id: Int
                    nonisolated(unsafe) var hits: Int

                    init(title: String, id: Int, hits: Int) {
                        self.title = title
                        self.id = id
                        self.hits = hits
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - hits: The new value for `hits`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor func copying(
                        title: (String)? = nil,
                        id: (Int)? = nil,
                        hits: (Int)? = nil
                    ) -> Session {
                        Session(
                            title: title ?? self.title,
                            id: id ?? self.id,
                            hits: hits ?? self.hits
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro leaves an actor's mutable state alone when nothing it copies is on the main actor")
    func copyingMacroWithUncopiedMainActorPropertyInActor() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Session {
                @MainActor var summary: String { "" }
                var count: Int

                init(count: Int) {
                    self.count = count
                }
            }
            """,
            expandedSource: """
                actor Session {
                    @MainActor var summary: String { "" }
                    var count: Int

                    init(count: Int) {
                        self.count = count
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - count: The new value for `count`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        count: (Int)? = nil
                    ) -> Session {
                        Session(
                            count: count ?? self.count
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro lets a class copy a mutable property alongside a main-actor one")
    func copyingMacroWithMainActorAndMutablePropertyInClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Document {
                @MainActor var title: String
                var revision: Int

                init(title: String, revision: Int) {
                    self.title = title
                    self.revision = revision
                }
            }
            """,
            expandedSource: """
                final class Document {
                    @MainActor var title: String
                    var revision: Int

                    init(title: String, revision: Int) {
                        self.title = title
                        self.revision = revision
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    ///   - revision: The new value for `revision`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    @MainActor func copying(
                        title: (String)? = nil,
                        revision: (Int)? = nil
                    ) -> Document {
                        Document(
                            title: title ?? self.title,
                            revision: revision ?? self.revision
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
