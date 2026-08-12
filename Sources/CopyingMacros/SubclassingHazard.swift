import SwiftDiagnostics
import SwiftSyntax

/// The slicing that `@Copying` opens up on a `class` that can still be subclassed.
///
/// The generated `copying` builds the copy by calling the annotated type's own
/// initializer and returns it as that type. A subclass inherits that method
/// unchanged, so copying through it rebuilds only the superclass part of the
/// instance: the subclass's own stored properties are dropped and the dynamic type
/// changes. Nothing in the language catches that — the call type-checks and the copy
/// is silently the wrong instance — so the macro warns and offers to close the hole
/// by marking the class `final`.
///
/// A `struct` and an `actor` cannot be subclassed, so this only ever applies to a
/// `class`.
struct SubclassingHazard {
    /// The class that carries the hazard.
    private let declaration: ClassDeclSyntax

    /// Creates the hazard `declaration` carries, or `nil` when it carries none: only a
    /// `class` can be subclassed, and a `final` one already rules it out.
    init?(declaration: some DeclGroupSyntax) {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self),
            !classDeclaration.modifiers.contains(anyOf: .final)
        else {
            return nil
        }
        self.declaration = classDeclaration
    }

    /// The node the diagnostic is anchored to: the `class` keyword, which is where the
    /// missing `final` belongs.
    var anchor: TokenSyntax {
        declaration.classKeyword
    }
}

extension SubclassingHazard {
    /// A Fix-It that marks the class `final`.
    ///
    /// `final` goes after whatever modifier the class already carries, where Swift
    /// itself writes it (`public final class`). An `open` class is demoted to `public`
    /// on the way, since `open` and `final` contradict each other: that keeps the class
    /// visible everywhere it was and takes away only the subclassing that causes the
    /// trouble.
    func fixIt() -> FixIt {
        let modifiers = DeclModifierListSyntax(
            declaration.modifiers.map { modifier in
                guard modifier.name.tokenKind == .keyword(.open) else {
                    return modifier
                }
                return modifier.with(\.name, modifier.name.with(\.tokenKind, .keyword(.public)))
            }
        )
        // With no modifier ahead of it, `final` takes over the `class` keyword's place
        // on the line, so it has to take that keyword's leading trivia — the newline
        // and indentation that put it there — along with it.
        let final = DeclModifierSyntax(
            leadingTrivia: modifiers.isEmpty ? declaration.classKeyword.leadingTrivia : [],
            name: .keyword(.final),
            trailingTrivia: .space
        )

        var changes: [FixIt.Change] = [
            .replace(oldNode: Syntax(declaration.modifiers), newNode: Syntax(modifiers + [final]))
        ]
        if modifiers.isEmpty {
            changes.append(.replaceLeadingTrivia(token: declaration.classKeyword, newTrivia: []))
        }

        return FixIt(
            message: CopyingFixItMessage.markFinal(typeName: declaration.name.text),
            changes: changes
        )
    }
}
