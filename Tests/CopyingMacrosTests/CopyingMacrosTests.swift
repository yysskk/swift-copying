import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

import CopyingMacros

let testMacros: [String: Macro.Type] = [
    "Copying": CopyingMacro.self,
]

@Suite("CopyingMacro Tests")
struct CopyingMacrosTests {
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
            class User {
                let id: Int
                var username: String
            }
            """,
            expandedSource: """
            class User {
                let id: Int
                var username: String

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - id: The new value for `id`, or `nil` to keep the current value.
                ///   - username: The new value for `username`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    id: Int? = nil,
                    username: String? = nil
                ) -> User {
                    return User(
                        id: id ?? self.id,
                        username: username ?? self.username
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

    @Test("Copying macro skips computed properties")
    func copyingMacroSkipsComputedProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Rectangle {
                let width: Double
                let height: Double
                var area: Double {
                    width * height
                }
            }
            """,
            expandedSource: """
            struct Rectangle {
                let width: Double
                let height: Double
                var area: Double {
                    width * height
                }

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - width: The new value for `width`, or `nil` to keep the current value.
                ///   - height: The new value for `height`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    width: Double? = nil,
                    height: Double? = nil
                ) -> Rectangle {
                    Rectangle(
                        width: width ?? self.width,
                        height: height ?? self.height
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Copying macro skips static properties")
    func copyingMacroSkipsStaticProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Counter {
                static let maxValue: Int = 100
                let value: Int
            }
            """,
            expandedSource: """
            struct Counter {
                static let maxValue: Int = 100
                let value: Int

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - value: The new value for `value`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    value: Int? = nil
                ) -> Counter {
                    Counter(
                        value: value ?? self.value
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
            class Container<T> {
                let item: T
            }
            """,
            expandedSource: """
            class Container<T> {
                let item: T

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - item: The new value for `item`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    item: T? = nil
                ) -> Container<T> {
                    return Container(
                        item: item ?? self.item
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
            }
            """,
            expandedSource: """
            actor Counter {
                let id: Int
                var value: Int

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - id: The new value for `id`, or `nil` to keep the current value.
                ///   - value: The new value for `value`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    id: Int? = nil,
                    value: Int? = nil
                ) -> Counter {
                    return Counter(
                        id: id ?? self.id,
                        value: value ?? self.value
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
            }
            """,
            expandedSource: """
            actor Storage<T: Sendable> {
                let data: T

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - data: The new value for `data`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    data: T? = nil
                ) -> Storage<T> {
                    return Storage(
                        data: data ?? self.data
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Access Level Tests

    @Test("Copying macro with public struct")
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

    @Test("Copying macro with package struct")
    func copyingMacroWithPackageStruct() {
        assertMacroExpansionForTesting(
            """
            @Copying
            package struct Settings {
                let theme: String
            }
            """,
            expandedSource: """
            package struct Settings {
                let theme: String

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - theme: The new value for `theme`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                package func copying(
                    theme: String? = nil
                ) -> Settings {
                    Settings(
                        theme: theme ?? self.theme
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Diagnostic Tests

    @Test("Copying macro warns about property without type annotation")
    func copyingMacroWarnsAboutMissingTypeAnnotation() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Config {
                let name: String
                let value = 42
            }
            """,
            expandedSource: """
            struct Config {
                let name: String
                let value = 42

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - name: The new value for `name`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    name: String? = nil
                ) -> Config {
                    Config(
                        name: name ?? self.name
                    )
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Property 'value' is missing a type annotation and will be excluded from the copying method",
                    line: 4,
                    column: 9,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }
}
