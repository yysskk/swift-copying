import SwiftSyntax

/// An access level the macro can give a member it generates, ordered from the least
/// to the most visible.
///
/// The order the cases are written in is the order they compare in, so `min` picks
/// the less visible of two levels. There is no `open` case: the macro generates a
/// factory method rather than something to override, so an `open` declaration
/// contributes `public`.
enum AccessLevel: Comparable {
    case `private`
    case `fileprivate`
    case `internal`
    case package
    case `public`
}

extension AccessLevel {
    /// The level a type carrying `modifiers` allows the members generated inside it.
    ///
    /// A type's own level is adjusted in one place, so that a generated member is
    /// usable everywhere the type itself is: a `private` type yields `fileprivate`,
    /// because a `private` member would be confined to the type declaration, while a
    /// `private` type remains usable in the rest of the file.
    init(forMembersOfTypeWith modifiers: DeclModifierListSyntax) {
        let declared = AccessLevel.declared(in: modifiers) ?? .internal
        self = declared == .private ? .fileprivate : declared
    }

    /// The level a stored property carrying `modifiers` can be read at.
    ///
    /// A `private` property keeps `private` here, unlike a `private` type: the
    /// generated member sits inside the type declaration, which is exactly as far as
    /// such a property is visible.
    init(ofPropertyWith modifiers: DeclModifierListSyntax) {
        self = AccessLevel.declared(in: modifiers) ?? .internal
    }

    /// The level for the members `@Copying` generates: the annotated type's level,
    /// capped at the least visible property the copy carries.
    ///
    /// This is the rule Swift applies to a struct's memberwise initializer, for the
    /// same two reasons. A method more visible than a property it copies would let
    /// code that cannot see the property vary it, defeating the property's own access
    /// level. And a method more visible than a copied property's type does not
    /// compile at all, since its parameter would name a type its callers cannot see.
    static func forGeneratedMembers(
        ofTypeWith modifiers: DeclModifierListSyntax,
        copying storedProperties: [StoredProperty]
    ) -> AccessLevel {
        storedProperties.reduce(AccessLevel(forMembersOfTypeWith: modifiers)) { level, property in
            min(level, property.accessLevel)
        }
    }

    /// The modifier generated code spells for this level, with the trailing space that
    /// separates it from what follows.
    ///
    /// `internal` renders as nothing, which is the level a declaration without an
    /// access-level modifier already carries.
    var rendered: String {
        switch self {
        case .private:
            return "private "
        case .fileprivate:
            return "fileprivate "
        case .internal:
            return ""
        case .package:
            return "package "
        case .public:
            return "public "
        }
    }

    /// The level `modifiers` spell out, or `nil` when they declare none and the
    /// declaration is therefore implicitly `internal`.
    private static func declared(in modifiers: DeclModifierListSyntax) -> AccessLevel? {
        for modifier in modifiers {
            // A modifier carrying a detail, such as `private(set)`, constrains the
            // setter alone. `copying` reads a property and passes the value on to an
            // initializer, so only read access limits who can call it.
            guard modifier.detail == nil else {
                continue
            }
            switch modifier.name.tokenKind {
            case .keyword(.private):
                return .private
            case .keyword(.fileprivate):
                return .fileprivate
            case .keyword(.internal):
                return .internal
            case .keyword(.package):
                return .package
            case .keyword(.public), .keyword(.open):
                return .public
            default:
                continue
            }
        }
        return nil
    }
}
