import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Expansion Tests")
struct ExpansionTests {
    @Test("Copying macro with struct")
    func copyingMacroWithStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Person {
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
                struct Person {
                    let name: String
                    let age: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - age: The new value for `age`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
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

    @Test("Copying macro with class")
    func copyingMacroWithClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int
                var username: String

                init(id: Int, username: String) {
                    self.id = id
                    self.username = username
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int
                    var username: String

                    init(id: Int, username: String) {
                        self.id = id
                        self.username = username
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - username: The new value for `username`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
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
            macros: testMacros
        )
    }

    @Test("Copying macro with actor")
    func copyingMacroWithActor() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Counter {
                let id: Int
                var value: Int

                init(id: Int, value: Int) {
                    self.id = id
                    self.value = value
                }
            }
            """,
            expandedSource: """
                actor Counter {
                    let id: Int
                    var value: Int

                    init(id: Int, value: Int) {
                        self.id = id
                        self.value = value
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (Int)? = nil,
                        value: (Int)? = nil
                    ) -> Counter {
                        Counter(
                            id: id ?? self.id,
                            value: value ?? self.value
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with optional properties")
    func copyingMacroWithOptionalProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Config {
                let name: String
                let value: Int?
            }
            """,
            expandedSource: """
                struct Config {
                    let name: String
                    let value: Int?

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil,
                        value: (Int?)? = nil
                    ) -> Config {
                        Config(
                            name: name ?? self.name,
                            value: value ?? self.value
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro spells an implicitly unwrapped optional property as a plain optional")
    func copyingMacroWithImplicitlyUnwrappedOptionalProperty() {
        // Swift only accepts `!` at the top level of a property's or a parameter's type,
        // so the parameter is spelled `(String?)?`; the `(String!)?` the declared type
        // would produce does not compile. It denotes the same type, and the double
        // optional behaves exactly as a plain optional property's does.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Screen {
                var title: String
                var subtitle: String!
            }
            """,
            expandedSource: """
                struct Screen {
                    var title: String
                    var subtitle: String!

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    ///   - subtitle: The new value for `subtitle`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: (String)? = nil,
                        subtitle: (String?)? = nil
                    ) -> Screen {
                        Screen(
                            title: title ?? self.title,
                            subtitle: subtitle ?? self.subtitle
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro keeps an implicitly unwrapped optional in the initializer it writes")
    func copyingMacroWithImplicitlyUnwrappedOptionalPropertyInFixIt() {
        // Only the `copying` parameter has to drop the `!`, because it nests the type in
        // another optional. An initializer parameter is a top-level position, so the
        // Fix-It writes the property's type as declared — the memberwise initializer a
        // `struct` would have been given.
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Screen {
                var subtitle: String!
            }
            """,
            expandedSource: """
                final class Screen {
                    var subtitle: String!

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - subtitle: The new value for `subtitle`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        subtitle: (String?)? = nil
                    ) -> Screen {
                        Screen(
                            subtitle: subtitle ?? self.subtitle
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Screen' to declare 'init(subtitle:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(subtitle:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(subtitle:)'"],
            fixedSource: """
                @Copying
                final class Screen {
                    var subtitle: String!

                    init(subtitle: String!) {
                        self.subtitle = subtitle
                    }
                }
                """
        )
    }

    @Test("Copying macro with generic struct")
    func copyingMacroWithGenericStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Box<T> {
                let value: T
            }
            """,
            expandedSource: """
                struct Box<T> {
                    let value: T

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        value: (T)? = nil
                    ) -> Box<T> {
                        Box(
                            value: value ?? self.value
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with multiple generic parameters")
    func copyingMacroWithMultipleGenericParameters() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Pair<K, V> {
                let key: K
                let value: V
            }
            """,
            expandedSource: """
                struct Pair<K, V> {
                    let key: K
                    let value: V

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - key: The new value for `key`, or `nil` to keep the current value.
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        key: (K)? = nil,
                        value: (V)? = nil
                    ) -> Pair<K, V> {
                        Pair(
                            key: key ?? self.key,
                            value: value ?? self.value
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with generic class")
    func copyingMacroWithGenericClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Container<T> {
                let item: T

                init(item: T) {
                    self.item = item
                }
            }
            """,
            expandedSource: """
                final class Container<T> {
                    let item: T

                    init(item: T) {
                        self.item = item
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - item: The new value for `item`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        item: (T)? = nil
                    ) -> Container<T> {
                        Container(
                            item: item ?? self.item
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with generic actor")
    func copyingMacroWithGenericActor() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Storage<T: Sendable> {
                let data: T

                init(data: T) {
                    self.data = data
                }
            }
            """,
            expandedSource: """
                actor Storage<T: Sendable> {
                    let data: T

                    init(data: T) {
                        self.data = data
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - data: The new value for `data`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        data: (T)? = nil
                    ) -> Storage<T> {
                        Storage(
                            data: data ?? self.data
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with generic types")
    func copyingMacroWithGenericType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Container {
                let items: [String]
                let mapping: [String: Int]
            }
            """,
            expandedSource: """
                struct Container {
                    let items: [String]
                    let mapping: [String: Int]

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - items: The new value for `items`, or `nil` to keep the current value.
                    ///   - mapping: The new value for `mapping`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        items: ([String])? = nil,
                        mapping: ([String: Int])? = nil
                    ) -> Container {
                        Container(
                            items: items ?? self.items,
                            mapping: mapping ?? self.mapping
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with function type property")
    func copyingMacroWithFunctionType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Handler {
                let transform: (Int) -> String
                let completion: () -> Void
            }
            """,
            expandedSource: """
                struct Handler {
                    let transform: (Int) -> String
                    let completion: () -> Void

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - transform: The new value for `transform`, or `nil` to keep the current value.
                    ///   - completion: The new value for `completion`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        transform: ((Int) -> String)? = nil,
                        completion: (() -> Void)? = nil
                    ) -> Handler {
                        Handler(
                            transform: transform ?? self.transform,
                            completion: completion ?? self.completion
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with existential type property")
    func copyingMacroWithExistentialType() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Wrapper {
                let value: any P
                let values: [any P]
            }
            """,
            expandedSource: """
                struct Wrapper {
                    let value: any P
                    let values: [any P]

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    ///   - values: The new value for `values`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        value: (any P)? = nil,
                        values: ([any P])? = nil
                    ) -> Wrapper {
                        Wrapper(
                            value: value ?? self.value,
                            values: values ?? self.values
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }
}
