import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Initializer Requirement Tests")
struct InitializerRequirementTests {
    @Test("Copying macro warns when a class declares no initializer")
    func copyingMacroWarnsWhenClassDeclaresNoInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                var id: Int = 0
                var username: String = ""
            }
            """,
            expandedSource: """
                final class User {
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(id:username:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(id:username:)'"],
            fixedSource: """
                @Copying
                final class User {
                    var id: Int = 0
                    var username: String = ""

                    init(id: Int, username: String) {
                        self.id = id
                        self.username = username
                    }
                }
                """
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(id:username:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(id:username:)'"],
            // The existing initializer is left alone: only the author knows whether its
            // labels are a mistake or deliberate, and both may coexist.
            fixedSource: """
                @Copying
                final class User {
                    let id: Int
                    var username: String

                    init(id: Int, name: String) {
                        self.id = id
                        self.username = name
                    }

                    init(id: Int, username: String) {
                        self.id = id
                        self.username = username
                    }
                }
                """
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(value:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(value:)'"],
            fixedSource: """
                @Copying
                actor Counter {
                    var value: Int = 0

                    init(value: Int) {
                        self.value = value
                    }
                }
                """
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(x:y:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(x:y:)'"],
            // Writing the memberwise initializer out by hand is what a struct needs once
            // it has declared an initializer of its own.
            fixedSource: """
                @Copying
                struct Point {
                    var x: Int
                    var y: Int

                    init(origin: Void) {
                        self.x = 0
                        self.y = 0
                    }

                    init(x: Int, y: Int) {
                        self.x = x
                        self.y = y
                    }
                }
                """
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

    @Test("Copying macro warns when a copied property's parameter is variadic")
    func copyingMacroWarnsWhenInitializerParameterIsVariadic() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Post {
                let id: Int
                var tags: [String]

                init(id: Int, tags: String...) {
                    self.id = id
                    self.tags = tags
                }
            }
            """,
            // A variadic gathers its arguments one by one; the generated call passes
            // the property's array as a single value, which Swift does not accept.
            expandedSource: """
                final class Post {
                    let id: Int
                    var tags: [String]

                    init(id: Int, tags: String...) {
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
                    ) -> Post {
                        Post(
                            id: id ?? self.id,
                            tags: tags ?? self.tags
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Post' to declare 'init(id:tags:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(id:tags:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(id:tags:)'"],
            // The inserted initializer takes an array where the existing one takes a
            // variadic, so the two are overloads rather than a redeclaration.
            fixedSource: """
                @Copying
                final class Post {
                    let id: Int
                    var tags: [String]

                    init(id: Int, tags: String...) {
                        self.id = id
                        self.tags = tags
                    }

                    init(id: Int, tags: [String]) {
                        self.id = id
                        self.tags = tags
                    }
                }
                """
        )
    }

    @Test("Copying macro accepts a bare argument label for an escaped property name")
    func copyingMacroAcceptsBareLabelForEscapedPropertyName() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Theme {
                var `default`: String

                init(default value: String) {
                    self.`default` = value
                }
            }
            """,
            // Backticks escape an identifier rather than being part of it, and a label
            // needs none where a property does.
            expandedSource: """
                final class Theme {
                    var `default`: String

                    init(default value: String) {
                        self.`default` = value
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - default: The new value for `default`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        `default`: (String)? = nil
                    ) -> Theme {
                        Theme(
                            `default`: `default` ?? self.`default`
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro spells an escaped property's signature without backticks")
    func copyingMacroSpellsEscapedSignatureWithoutBackticks() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Theme {
                var `default`: String
            }
            """,
            expandedSource: """
                final class Theme {
                    var `default`: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - default: The new value for `default`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        `default`: (String)? = nil
                    ) -> Theme {
                        Theme(
                            `default`: `default` ?? self.`default`
                        )
                    }
                }
                """,
            // A compound name carries no backticks, which is how Swift itself writes
            // one; the initializer the Fix-It inserts still escapes the identifier.
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Theme' to declare 'init(default:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(default:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(default:)'"],
            fixedSource: """
                @Copying
                final class Theme {
                    var `default`: String

                    init(`default`: String) {
                        self.`default` = `default`
                    }
                }
                """
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(value:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(value:)'"],
            fixedSource: """
                @Copying
                final class Box {
                    let value: Int

                    init(_ value: Int) {
                        self.value = value
                    }

                    init(value: Int) {
                        self.value = value
                    }
                }
                """
        )
    }

    @Test("Copying macro warns when the initializer is failable")
    func copyingMacroWarnsWhenInitializerIsFailable() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init?(id: Int) {
                    guard id > 0 else {
                        return nil
                    }
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init?(id: Int) {
                        guard id > 0 else {
                            return nil
                        }
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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unusableInitializer"),
                    message:
                        "@Copying calls 'init(id:)' to build the copy, so it cannot be failable ('init?'), throwing, or async",
                    line: 5,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro accepts an implicitly unwrapped failable initializer")
    func copyingMacroAcceptsImplicitlyUnwrappedFailableInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init!(id: Int) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init!(id: Int) {
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

    @Test("Copying macro warns when the initializer throws")
    func copyingMacroWarnsWhenInitializerThrows() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init(id: Int) throws {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init(id: Int) throws {
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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unusableInitializer"),
                    message:
                        "@Copying calls 'init(id:)' to build the copy, so it cannot be failable ('init?'), throwing, or async",
                    line: 5,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro accepts a convenience initializer")
    func copyingMacroAcceptsConvenienceInitializer() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int
                var username: String

                init(id: Int) {
                    self.id = id
                    self.username = ""
                }

                convenience init(id: Int, username: String) {
                    self.init(id: id)
                    self.username = username
                }
            }
            """,
            // The call reaches a convenience initializer as readily as a designated
            // one, so how it is written does not matter to the check.
            expandedSource: """
                final class User {
                    let id: Int
                    var username: String

                    init(id: Int) {
                        self.id = id
                        self.username = ""
                    }

                    convenience init(id: Int, username: String) {
                        self.init(id: id)
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

    @Test("Copying macro accepts an initializer with a separate internal parameter name")
    func copyingMacroAcceptsInitializerWithInternalParameterName() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class Box {
                let id: Int

                init(id ident: Int) {
                    self.id = ident
                }
            }
            """,
            // Only the label a caller writes matters; the name the body uses is the
            // initializer's own business.
            expandedSource: """
                final class Box {
                    let id: Int

                    init(id ident: Int) {
                        self.id = ident
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - id: The new value for `id`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        id: (Int)? = nil
                    ) -> Box {
                        Box(
                            id: id ?? self.id
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro warns when the initializer is async and throwing")
    func copyingMacroWarnsWhenInitializerIsAsyncThrows() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init(id: Int) async throws {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init(id: Int) async throws {
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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unusableInitializer"),
                    message:
                        "@Copying calls 'init(id:)' to build the copy, so it cannot be failable ('init?'), throwing, or async",
                    line: 5,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro warns when the initializer is async")
    func copyingMacroWarnsWhenInitializerIsAsync() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init(id: Int) async {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init(id: Int) async {
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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "unusableInitializer"),
                    message:
                        "@Copying calls 'init(id:)' to build the copy, so it cannot be failable ('init?'), throwing, or async",
                    line: 5,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Copying macro prefers a usable initializer over an unusable one")
    func copyingMacroPrefersUsableInitializerOverUnusableOne() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let id: Int

                init?(id: Int) {
                    guard id > 0 else {
                        return nil
                    }
                    self.id = id
                }

                init(id: Int, verified: Bool = false) {
                    self.id = id
                }
            }
            """,
            expandedSource: """
                final class User {
                    let id: Int

                    init?(id: Int) {
                        guard id > 0 else {
                            return nil
                        }
                        self.id = id
                    }

                    init(id: Int, verified: Bool = false) {
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

    @Test("Copying macro Fix-It initializer carries the access level of the generated method")
    func copyingMacroFixItCarriesAccessLevel() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public actor Counter {
                public var value: Int = 0

                public func increment() {
                    value += 1
                }
            }
            """,
            expandedSource: """
                public actor Counter {
                    public var value: Int = 0

                    public func increment() {
                        value += 1
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - value: The new value for `value`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    public func copying(
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(value:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(value:)'"],
            fixedSource: """
                @Copying
                public actor Counter {
                    public var value: Int = 0

                    public func increment() {
                        value += 1
                    }

                    public init(value: Int) {
                        self.value = value
                    }
                }
                """
        )
    }

    @Test("Copying macro stays silent when the initializer is declared inside #if")
    func copyingMacroStaysSilentWhenInitializerIsConditional() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                var id: Int = 0
                #if os(iOS)
                init(id: Int) {
                    self.id = id
                }
                #endif
            }
            """,
            // A macro cannot know which branch a build takes, so warning here would be
            // wrong wherever this one is active — and the Fix-It would write a second
            // initializer with the same signature.
            expandedSource: """
                final class User {
                    var id: Int = 0
                    #if os(iOS)
                    init(id: Int) {
                        self.id = id
                    }
                    #endif

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

    @Test("Copying macro stays silent when a conditional initializer joins a non-matching one")
    func copyingMacroStaysSilentWhenConditionalInitializerJoinsANonMatchingOne() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                var id: Int = 0

                init() {
                }

                #if os(iOS)
                init(id: Int) {
                    self.id = id
                }
                #endif
            }
            """,
            expandedSource: """
                final class User {
                    var id: Int = 0

                    init() {
                    }

                    #if os(iOS)
                    init(id: Int) {
                        self.id = id
                    }
                    #endif

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

    @Test("Copying macro Fix-It initializer carries the capped access level")
    func copyingMacroFixItCarriesCappedAccessLevel() {
        assertMacroExpansionForTesting(
            """
            @Copying
            public actor Counter {
                var value: Int = 0
            }
            """,
            // The property is `internal`, so both the method and the initializer the
            // Fix-It writes stop there rather than following the `public` actor.
            expandedSource: """
                public actor Counter {
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
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(value:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(value:)'"],
            fixedSource: """
                @Copying
                public actor Counter {
                    var value: Int = 0

                    init(value: Int) {
                        self.value = value
                    }
                }
                """
        )
    }

    @Test("Copying macro Fix-It initializer follows tab indentation")
    func copyingMacroFixItFollowsTabIndentation() {
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
            \tvar id: Int = 0
            }
            """,
            // The expansion itself is laid out by the compiler, which indents it with
            // the width it is configured for; the Fix-It below is the macro's own
            // work, and follows the file's tabs.
            expandedSource: """
                final class User {
                \tvar id: Int = 0

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
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'User' to declare 'init(id:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(id:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(id:)'"],
            fixedSource: """
                @Copying
                final class User {
                \tvar id: Int = 0

                \tinit(id: Int) {
                \t\tself.id = id
                \t}
                }
                """
        )
    }

    @Test("Copying macro Fix-It initializer follows the indentation of a nested type")
    func copyingMacroFixItFollowsNestedIndentation() {
        assertMacroExpansionForTesting(
            """
            enum Namespace {
                @Copying
                final class Box {
                    let value: Int
                }
            }
            """,
            expandedSource: """
                enum Namespace {
                    final class Box {
                        let value: Int

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
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'Box' to declare 'init(value:)', which the generated 'copying' method calls",
                    line: 2,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(value:)'")]
                )
            ],
            macros: testMacros,
            applyFixIts: ["Add 'init(value:)'"],
            fixedSource: """
                enum Namespace {
                    @Copying
                    final class Box {
                        let value: Int

                        init(value: Int) {
                            self.value = value
                        }
                    }
                }
                """
        )
    }

    @Test("Copying macro warns when an initializer takes the arguments out of order")
    func copyingMacroWarnsWhenInitializerLabelsAreOutOfOrder() {
        // Swift matches arguments to parameters in declaration order, so a call passing
        // `name:` before `age:` cannot resolve to `init(age:name:)` however well the
        // labels themselves line up.
        assertMacroExpansionForTesting(
            """
            @Copying
            final class User {
                let name: String
                let age: Int

                init(age: Int, name: String) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            expandedSource: """
                final class User {
                    let name: String
                    let age: Int

                    init(age: Int, name: String) {
                        self.name = name
                        self.age = age
                    }

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - name: The new value for `name`, or `nil` to keep the current value.
                    ///   - age: The new value for `age`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        name: (String)? = nil,
                        age: (Int)? = nil
                    ) -> User {
                        User(
                            name: name ?? self.name,
                            age: age ?? self.age
                        )
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingInitializer"),
                    message:
                        "@Copying requires 'User' to declare 'init(name:age:)', which the generated 'copying' method calls",
                    line: 1,
                    column: 1,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Add 'init(name:age:)'")]
                )
            ],
            macros: testMacros
        )
    }

}
