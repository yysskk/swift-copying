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
                        name: String? = nil,
                        age: Int? = nil
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
                        id: Int? = nil,
                        username: String? = nil
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
                        id: Int? = nil,
                        value: Int? = nil
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
                    ///   - value: The new value for `value`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: String? = nil,
                        value: Int?? = nil
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

    // Only the spelling says a type is optional, so a typealias for one is documented
    // like any other type, while its parameter is still a double optional.
    @Test("Copying macro documents how to reset every spelling of an optional property")
    func copyingMacroDocumentsOptionalSpellings() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Config {
                let timeout: Optional<Int>
                let retries: Swift.Optional<Int>
                let jitter: (Int?)
                let delay: MaybeInt
            }
            """,
            expandedSource: """
                struct Config {
                    let timeout: Optional<Int>
                    let retries: Swift.Optional<Int>
                    let jitter: (Int?)
                    let delay: MaybeInt

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - timeout: The new value for `timeout`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    ///   - retries: The new value for `retries`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    ///   - jitter: The new value for `jitter`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    ///   - delay: The new value for `delay`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        timeout: Optional<Int>? = nil,
                        retries: Swift.Optional<Int>? = nil,
                        jitter: (Int?)? = nil,
                        delay: MaybeInt? = nil
                    ) -> Config {
                        Config(
                            timeout: timeout ?? self.timeout,
                            retries: retries ?? self.retries,
                            jitter: jitter ?? self.jitter,
                            delay: delay ?? self.delay
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
                    ///   - subtitle: The new value for `subtitle`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: String? = nil,
                        subtitle: String?? = nil
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
                    ///   - subtitle: The new value for `subtitle`, or `nil` to keep the current value; pass `.some(nil)` to reset it to `nil`.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        subtitle: String?? = nil
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
                        value: T? = nil
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
                        key: K? = nil,
                        value: V? = nil
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
                        item: T? = nil
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
                        data: T? = nil
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

    @Test("Copying macro with parameter pack")
    func copyingMacroWithParameterPack() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Bundle<each T> {
                let label: String
            }
            """,
            // A pack is referred to by expanding it: `Bundle<T>` is rejected with
            // "pack reference 'T' can only appear in pack expansion".
            expandedSource: """
                struct Bundle<each T> {
                    let label: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - label: The new value for `label`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        label: String? = nil
                    ) -> Bundle<repeat each T> {
                        Bundle(
                            label: label ?? self.label
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with a parameter pack alongside a plain generic parameter")
    func copyingMacroWithMixedGenericParameters() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Group<Label, each Item: Sendable> {
                let label: Label
                let count: Int
            }
            """,
            // Only the pack is expanded; a plain parameter, constrained or not, keeps
            // its bare name.
            expandedSource: """
                struct Group<Label, each Item: Sendable> {
                    let label: Label
                    let count: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - label: The new value for `label`, or `nil` to keep the current value.
                    ///   - count: The new value for `count`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        label: Label? = nil,
                        count: Int? = nil
                    ) -> Group<Label, repeat each Item> {
                        Group(
                            label: label ?? self.label,
                            count: count ?? self.count
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro with collection type properties")
    func copyingMacroWithCollectionTypeProperties() {
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
                        items: [String]? = nil,
                        mapping: [String: Int]? = nil
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
                        values: [any P]? = nil
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

    @Test("Copying macro parenthesizes a parameter type only where the optional mark needs it")
    func copyingMacroParenthesizesParameterTypeOnlyWhereNeeded() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Shapes {
                let name: Swift.String
                let pair: (Int, Int)
                let kind: Int.Type
                let anyKind: any Equatable.Type
                let key: any Hashable & Sendable
                let handler: @Sendable () -> Void
            }
            """,
            expandedSource: """
                struct Shapes {
                    let name: Swift.String
                    let pair: (Int, Int)
                    let kind: Int.Type
                    let anyKind: any Equatable.Type
                    let key: any Hashable & Sendable
                    let handler: @Sendable () -> Void

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - pair: The new value for `pair`, or `nil` to keep the current value.
                    ///   - kind: The new value for `kind`, or `nil` to keep the current value.
                    ///   - anyKind: The new value for `anyKind`, or `nil` to keep the current value.
                    ///   - key: The new value for `key`, or `nil` to keep the current value.
                    ///   - handler: The new value for `handler`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: Swift.String? = nil,
                        pair: (Int, Int)? = nil,
                        kind: Int.Type? = nil,
                        anyKind: (any Equatable.Type)? = nil,
                        key: (any Hashable & Sendable)? = nil,
                        handler: (@Sendable () -> Void)? = nil
                    ) -> Shapes {
                        Shapes(
                            name: name ?? self.name,
                            pair: pair ?? self.pair,
                            kind: kind ?? self.kind,
                            anyKind: anyKind ?? self.anyKind,
                            key: key ?? self.key,
                            handler: handler ?? self.handler
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    // A value generic parameter (SE-0452) parses from swift-syntax 601 on; an older one
    // does not recognize the `let` that introduces it.
    #if canImport(SwiftSyntax601)
        @Test("Copying macro with a value generic parameter")
        func copyingMacroWithValueGenericParameter() {
            assertMacroExpansionForTesting(
                """
                @Copying
                struct Grid<let columns: Int, Element> {
                    var cells: [Element]
                }
                """,
                expandedSource: """
                    struct Grid<let columns: Int, Element> {
                        var cells: [Element]

                        /// Creates a copy of this instance with the specified properties modified.
                        /// - Parameters:
                        ///   - cells: The new value for `cells`, or `nil` to keep the current value.
                        /// - Returns: A new instance with the specified modifications.
                        func copying(
                            cells: [Element]? = nil
                        ) -> Grid<columns, Element> {
                            Grid(
                                cells: cells ?? self.cells
                            )
                        }
                    }
                    """,
                macros: testMacros
            )
        }

    #endif

    // The `[n of T]` sugar for `InlineArray` (SE-0483) parses as a type from
    // swift-syntax 602 on; an older one reads it as something else entirely.
    #if canImport(SwiftSyntax602)
        @Test("Copying macro with an inline array property")
        func copyingMacroWithInlineArrayProperty() {
            assertMacroExpansionForTesting(
                """
                @Copying
                struct Buffer<let count: Int> {
                    var storage: [count of Int]
                }
                """,
                expandedSource: """
                    struct Buffer<let count: Int> {
                        var storage: [count of Int]

                        /// Creates a copy of this instance with the specified properties modified.
                        /// - Parameters:
                        ///   - storage: The new value for `storage`, or `nil` to keep the current value.
                        /// - Returns: A new instance with the specified modifications.
                        func copying(
                            storage: [count of Int]? = nil
                        ) -> Buffer<count> {
                            Buffer(
                                storage: storage ?? self.storage
                            )
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    #endif
}
