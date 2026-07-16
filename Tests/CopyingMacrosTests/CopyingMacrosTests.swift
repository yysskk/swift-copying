import CopyingMacros
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

let testMacros: [String: Macro.Type] = [
    "Copying": CopyingMacro.self
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

                init(id: Int, username: String) {
                    self.id = id
                    self.username = username
                }
            }
            """,
            expandedSource: """
                class User {
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

    @Test("Copying macro keeps observed stored properties and skips explicitly computed ones")
    func copyingMacroHandlesAccessorBlocks() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Model {
                var name: String {
                    didSet {
                        print(name)
                    }
                }
                var length: Int {
                    get {
                        name.count
                    }
                }
            }
            """,
            expandedSource: """
                struct Model {
                    var name: String {
                        didSet {
                            print(name)
                        }
                    }
                    var length: Int {
                        get {
                            name.count
                        }
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil
                    ) -> Model {
                        Model(
                            name: name ?? self.name
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

    @Test("Copying macro skips let constants with initial values")
    func copyingMacroSkipsInitializedLetConstants() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Counter {
                let maxValue: Int = 100
                var value: Int
            }
            """,
            expandedSource: """
                struct Counter {
                    let maxValue: Int = 100
                    var value: Int

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

    @Test("Copying macro keeps uninitialized bindings in a declaration with an initialized let")
    func copyingMacroKeepsUninitializedBindingNextToInitializedLet() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Sample {
                let a: Int = 1, b: Int
            }
            """,
            expandedSource: """
                struct Sample {
                    let a: Int = 1, b: Int

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - b: The new value for `b`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        b: (Int)? = nil
                    ) -> Sample {
                        Sample(
                            b: b ?? self.b
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro skips lazy properties")
    func copyingMacroSkipsLazyProperties() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct DataStore {
                var name: String
                lazy var cache: [String] = []
            }
            """,
            expandedSource: """
                struct DataStore {
                    var name: String
                    lazy var cache: [String] = []

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil
                    ) -> DataStore {
                        DataStore(
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

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

    @Test("Copying macro reports every offending property in one expansion")
    func copyingMacroReportsMultipleViolationsTogether() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Broken {
                var count = 0
                var (x, y) = (0, 0)
            }
            """,
            expandedSource: """
                struct Broken {
                    var count = 0
                    var (x, y) = (0, 0)
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
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro warns when a class declares no initializer")
    func copyingMacroWarnsWhenClassDeclaresNoInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            class User {
                var id: Int = 0
                var username: String = ""
            }
            """,
            expandedSource: """
                class User {
                    var id: Int = 0
                    var username: String = ""

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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'User' to declare 'init(id:username:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro warns when an initializer has different argument labels")
    func copyingMacroWarnsWhenInitializerLabelsDiffer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int
                var username: String

                init(id: Int, name: String) {
                    self.id = id
                    self.username = name
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int
                    var username: String

                    init(id: Int, name: String) {
                        self.id = id
                        self.username = name
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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'User' to declare 'init(id:username:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro warns when an actor declares no initializer")
    func copyingMacroWarnsWhenActorDeclaresNoInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            actor Counter {
                var value: Int = 0
            }
            """,
            expandedSource: """
                actor Counter {
                    var value: Int = 0

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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Counter' to declare 'init(value:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro warns when a struct suppresses its memberwise initializer")
    func copyingMacroWarnsWhenStructSuppressesMemberwiseInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Point {
                var x: Int
                var y: Int

                init(origin: Void) {
                    self.x = 0
                    self.y = 0
                }
            }
            """,
            expandedSource: """
                struct Point {
                    var x: Int
                    var y: Int

                    init(origin: Void) {
                        self.x = 0
                        self.y = 0
                    }

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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Point' to declare 'init(x:y:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro accepts an initializer with extra omittable parameters")
    func copyingMacroAcceptsInitializerWithOmittableParameters() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int
                var tags: [String]

                init(audit: Bool = false, id: Int, notes: String..., tags: [String]) {
                    self.id = id
                    self.tags = tags
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int
                    var tags: [String]

                    init(audit: Bool = false, id: Int, notes: String..., tags: [String]) {
                        self.id = id
                        self.tags = tags
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    ///   - tags: The new value for `tags`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (Int)? = nil,
                        tags: ([String])? = nil
                    ) -> User {
                        User(
                            id: id ?? self.id,
                            tags: tags ?? self.tags
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro warns when an initializer takes an unlabelled argument")
    func copyingMacroWarnsWhenInitializerTakesUnlabelledArgument() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Box {
                let value: Int

                init(_ value: Int) {
                    self.value = value
                }
            }
            """,
            expandedSource: """
                final class Box {
                    let value: Int

                    init(_ value: Int) {
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
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Box' to declare 'init(value:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro accepts a matching initializer among several overloads")
    func copyingMacroAcceptsMatchingInitializerAmongOverloads() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init() {
                    self.id = 0
                }

                init(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init() {
                        self.id = 0
                    }

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

                init(item: T) {
                    self.item = item
                }
            }
            """,
            expandedSource: """
                class Container<T> {
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
