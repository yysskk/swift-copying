import SwiftDiagnostics
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("CopyingMacro Multiple Binding Tests")
struct MultipleBindingTests {
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

    @Test("Copying macro shares one type annotation across the bindings of a declaration")
    func copyingMacroSharesTypeAnnotationAcrossBindings() {
        // `var x, y: Int` declares two `Int` properties, but the annotation is attached
        // only to `y`. Every preceding binding takes it, so neither is treated as
        // missing a type.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Point {
                var x, y: Int
            }
            """,
            expandedSource: """
                struct Point {
                    var x, y: Int

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

    @Test("Copying macro shares each type annotation with the bindings that precede it")
    func copyingMacroSharesEachTypeAnnotationWithPrecedingBindings() {
        // A declaration can spell out several annotations, each covering the bindings
        // up to it, and a `let` shares them the same way.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Rect {
                let x, y: Int, label, unit: String
            }
            """,
            expandedSource: """
                struct Rect {
                    let x, y: Int, label, unit: String

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - x: The new value for `x`, or `nil` to keep the current value.
                    ///   - y: The new value for `y`, or `nil` to keep the current value.
                    ///   - label: The new value for `label`, or `nil` to keep the current value.
                    ///   - unit: The new value for `unit`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        x: (Int)? = nil,
                        y: (Int)? = nil,
                        label: (String)? = nil,
                        unit: (String)? = nil
                    ) -> Rect {
                        Rect(
                            x: x ?? self.x,
                            y: y ?? self.y,
                            label: label ?? self.label,
                            unit: unit ?? self.unit
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Copying macro shares an implicitly unwrapped optional annotation across bindings")
    func copyingMacroSharesImplicitlyUnwrappedOptionalAnnotation() {
        // A shared annotation reaches every binding as the declaration spells it, so
        // both properties are implicitly unwrapped and both parameters drop the `!`.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Screen {
                var title, subtitle: String!
            }
            """,
            expandedSource: """
                struct Screen {
                    var title, subtitle: String!

                    /// Creates a copy of this instance with the specified properties modified.
                    /// - Parameters:
                    ///   - title: The new value for `title`, or `nil` to keep the current value.
                    ///   - subtitle: The new value for `subtitle`, or `nil` to keep the current value.
                    /// - Returns: A new instance with the specified modifications.
                    func copying(
                        title: (String?)? = nil,
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

    @Test("Copying macro stops sharing a type annotation at a binding with an initial value")
    func copyingMacroStopsSharingTypeAnnotationAtInitializedBinding() {
        // An initial value makes a binding infer its own type, which the macro cannot
        // see, and ends the sharing: `count` is an `Int` of its own and `name` keeps
        // its annotation to itself. Swift rejects `var x, y: Int = 0` for the same
        // reason, so nothing valid is lost by reporting `count` here.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Sample {
                var count = 0, name: String
            }
            """,
            expandedSource: """
                struct Sample {
                    var count = 0, name: String
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

    @Test("Copying macro reports a trailing binding with no type annotation to share")
    func copyingMacroReportsTrailingBindingWithoutTypeAnnotation() {
        // Only a *later* binding's annotation is shared, matching Swift: `var x: Int, y`
        // leaves `y` without a type.
        assertMacroExpansionForTesting(
            """
            @Copying
            struct Sample {
                var x: Int, y
            }
            """,
            expandedSource: """
                struct Sample {
                    var x: Int, y
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    id: MessageID(domain: "CopyingMacros", id: "missingTypeAnnotation"),
                    message: "@Copying requires an explicit type annotation for 'y'",
                    line: 3,
                    column: 17
                )
            ],
            macros: testMacros
        )
    }
}
