import SwiftSyntax

extension DeclModifierListSyntax {
    /// Whether the list contains a modifier spelled with any of `keywords`.
    func contains(anyOf keywords: Keyword...) -> Bool {
        contains { modifier in
            keywords.contains { modifier.name.tokenKind == .keyword($0) }
        }
    }
}
