import SwiftSyntaxMacros
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
                    id: (Int)? = nil,
                    username: (String)? = nil
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
                    width: (Double)? = nil,
                    height: (Double)? = nil
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
                    value: (Int)? = nil
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

    @Test("Copying macro with multiple bindings in a single declaration")
    func copyingMacroWithMultipleBindingsInSingleDeclaration() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Point {
                let x: Int, y: Int
            }
            """,
            expandedSource: """
            struct Point {
                let x: Int, y: Int

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - x: The new value for `x`, or `nil` to keep the current value.
                ///   - y: The new value for `y`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    x: (Int)? = nil,
                    y: (Int)? = nil
                ) -> Point {
                    Point(
                        x: x ?? self.x,
                        y: y ?? self.y
                    )
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Copying macro with multiple bindings of different types mixed with single bindings")
    func copyingMacroWithMultipleBindingsOfDifferentTypes() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Person {
                let name: String, age: Int
                let email: String
            }
            """,
            expandedSource: """
            struct Person {
                let name: String, age: Int
                let email: String

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - name: The new value for `name`, or `nil` to keep the current value.
                ///   - age: The new value for `age`, or `nil` to keep the current value.
                ///   - email: The new value for `email`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                func copying(
                    name: (String)? = nil,
                    age: (Int)? = nil,
                    email: (String)? = nil
                ) -> Person {
                    Person(
                        name: name ?? self.name,
                        age: age ?? self.age,
                        email: email ?? self.email
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
                    item: (T)? = nil
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
                    id: (Int)? = nil,
                    value: (Int)? = nil
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
                    data: (T)? = nil
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
            }
            """,
            expandedSource: """
            open class User {
                let id: Int
                var username: String

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - id: The new value for `id`, or `nil` to keep the current value.
                ///   - username: The new value for `username`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                public func copying(
                    id: (Int)? = nil,
                    username: (String)? = nil
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

    @Test("Copying macro picks access level among multiple modifiers")
    func copyingMacroWithPublicFinalClass() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public final class User {
                let id: Int
            }
            """,
            expandedSource: """
            public final class User {
                let id: Int

                /// Creates a copy of this instance with the specified properties modified.
                /// - Parameters:
                ///   - id: The new value for `id`, or `nil` to keep the current value.
                /// - Returns: A new instance with the specified modifications.
                public func copying(
                    id: (Int)? = nil
                ) -> User {
                    return User(
                        id: id ?? self.id
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
