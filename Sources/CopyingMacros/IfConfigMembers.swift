import SwiftSyntax

extension IfConfigDeclSyntax {
    /// Every member this directive declares, across all of its clauses — `#elseif` and
    /// `#else` included — with the members of a nested directive flattened in.
    ///
    /// A macro is handed the declaration as it is written, conditional directives and
    /// all, and the compiler resolves them afterwards. A member inside `#if` is
    /// therefore wrapped in one of these rather than being a member of the type's
    /// block, which is why looking for one among the block's members alone misses it.
    var conditionalMembers: [MemberBlockItemSyntax] {
        clauses.flatMap { clause -> [MemberBlockItemSyntax] in
            guard case .decls(let members)? = clause.elements else {
                return []
            }
            return members.flatMap { member -> [MemberBlockItemSyntax] in
                guard let nested = member.decl.as(IfConfigDeclSyntax.self) else {
                    return [member]
                }
                return nested.conditionalMembers
            }
        }
    }
}
