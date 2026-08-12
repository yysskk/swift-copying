import SwiftSyntax

extension DeclModifierListSyntax {
    /// Whether the list contains a modifier spelled with any of `keywords`.
    func contains(anyOf keywords: Keyword...) -> Bool {
        contains { modifier in
            keywords.contains { modifier.name.tokenKind == .keyword($0) }
        }
    }

    /// The access-level modifier (with a trailing space) to apply to the members the
    /// macro generates for a type carrying these modifiers.
    ///
    /// Empty when the type has no explicit access-level modifier (i.e. the default
    /// `internal`). Two levels are adjusted so that a generated member is callable
    /// from everywhere the type itself is visible:
    /// - `open` is mapped to `public` because the generated method is a factory that
    ///   never needs to be overridden.
    /// - `private` is mapped to `fileprivate` because a `private` member would be
    ///   confined to the type declaration itself, while a `private` type remains
    ///   usable in the rest of the file.
    var accessLevelForGeneratedMembers: String {
        for modifier in self {
            switch modifier.name.tokenKind {
            case .keyword(.open):
                return "public "
            case .keyword(.private):
                return "fileprivate "
            case .keyword(.public), .keyword(.package), .keyword(.internal), .keyword(.fileprivate):
                return "\(modifier.name.text) "
            default:
                continue
            }
        }
        return ""
    }
}
