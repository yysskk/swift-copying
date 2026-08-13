import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Property Selection Tests")
struct PropertySelectionTests {
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

    @Test("Copying macro skips members inside #if that a copy never carries")
    func copyingMacroSkipsNonCopyableConditionalMembers() {
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Settings {
                var name: String
                #if DEBUG
                static let shared: Int = 0
                let limit: Int = 3
                var doubled: Int {
                    limit * 2
                }
                #endif
            }
            """,
            // Only a property a copy would have to carry makes a directive a problem;
            // these are skipped inside `#if` exactly as they are outside it.
            expandedSource: """
                struct Settings {
                    var name: String
                    #if DEBUG
                    static let shared: Int = 0
                    let limit: Int = 3
                    var doubled: Int {
                        limit * 2
                    }
                    #endif

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil
                    ) -> Settings {
                        Settings(
                            name: name ?? self.name
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

    @Test("Copying macro includes a weak stored property")
    func copyingMacroIncludesWeakProperty() {
        // `weak` is a storage specifier, not one of the modifiers that exclude a
        // property (`static`/`class`/`lazy`), so a weak reference is copied like any
        // other stored property. Its optional type produces a double optional
        // parameter, exactly as a plain optional would.
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Node {
                var name: String
                weak var next: Node?
            }
            """,
            expandedSource: """
                final class Node {
                    var name: String
                    weak var next: Node?

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - next: The new value for `next`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil,
                        next: (Node?)? = nil
                    ) -> Node {
                        Node(
                            name: name ?? self.name,
                            next: next ?? self.next
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Node' to declare 'init(name:next:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(name:next:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(name:next:)'"],
            // The Fix-It carries the weak property through unchanged: its parameter keeps
            // the optional type and the assignment stores it back into the weak variable.
            fixedSource: """
                @Copying
                final class Node {
                    var name: String
                    weak var next: Node?

                    init(name: String, next: Node?) {
                        self.name = name
                        self.next = next
                    }
                }
                """
        )
    }

    @Test("Copying macro includes an unowned stored property")
    func copyingMacroIncludesUnownedProperty() {
        // `unowned` is likewise only a storage specifier, so a non-optional unowned
        // reference is copied as a non-optional parameter.
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Edge {
                unowned var origin: Node
                var label: String

                init(origin: Node, label: String) {
                    self.origin = origin
                    self.label = label
                }
            }
            """,
            expandedSource: """
                final class Edge {
                    unowned var origin: Node
                    var label: String

                    init(origin: Node, label: String) {
                        self.origin = origin
                        self.label = label
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - origin: The new value for `origin`, or `nil` to keep the current value.
                    ///   - label: The new value for `label`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        origin: (Node)? = nil,
                        label: (String)? = nil
                    ) -> Edge {
                        Edge(
                            origin: origin ?? self.origin,
                            label: label ?? self.label
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro copies a property-wrapped property by its wrapped type")
    func copyingMacroCopiesPropertyWrapper() {
        // The macro reads only the property's annotated (wrapped) type and ignores the
        // wrapper attribute, so a wrapped property is copied like any other. This is
        // correct as long as the wrapper offers `init(wrappedValue:)`: the synthesized
        // memberwise initializer then takes the wrapped type, which is exactly what the
        // generated call passes.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Settings {
                @Uppercased var code: String
                var name: String
            }
            """,
            expandedSource: """
                struct Settings {
                    @Uppercased var code: String
                    var name: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - code: The new value for `code`, or `nil` to keep the current value.
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        code: (String)? = nil,
                        name: (String)? = nil
                    ) -> Settings {
                        Settings(
                            code: code ?? self.code,
                            name: name ?? self.name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro copies a property wrapper that takes attribute arguments")
    func copyingMacroCopiesPropertyWrapperWithArguments() {
        // Attribute arguments and an initial value do not change what the macro sees:
        // it still copies the property by its wrapped type. The memberwise initializer
        // reapplies the wrapper's arguments, so the configuration survives a copy.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Volume {
                @Clamped(range: 0...11) var level: Int = 5
                var label: String
            }
            """,
            expandedSource: """
                struct Volume {
                    @Clamped(range: 0...11) var level: Int = 5
                    var label: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - level: The new value for `level`, or `nil` to keep the current value.
                    ///   - label: The new value for `label`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        level: (Int)? = nil,
                        label: (String)? = nil
                    ) -> Volume {
                        Volume(
                            level: level ?? self.level,
                            label: label ?? self.label
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro skips a let tuple binding without reporting it")
    func copyingMacroSkipsLetTuplePatternBinding() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Screen {
                let (width, height) = (0, 0)
                var title: String

                init(title: String) {
                    self.title = title
                }
            }
            """,
            expandedSource: """
                final class Screen {
                    let (width, height) = (0, 0)
                    var title: String

                    init(title: String) {
                        self.title = title
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: (String)? = nil
                    ) -> Screen {
                        Screen(
                            title: title ?? self.title
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro skips class type properties")
    func copyingMacroSkipsClassTypeProperties() {
        // Spelled as storage so that the `class` modifier is the only reason it is
        // skipped. Swift rejects a stored `class` property, but the macro sees syntax
        // alone, and the modifier has to be what stops it either way.
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Counter {
                class var maxValue: Int = 100
                let value: Int

                init(value: Int) {
                    self.value = value
                }
            }
            """,
            expandedSource: """
                final class Counter {
                    class var maxValue: Int = 100
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

}
