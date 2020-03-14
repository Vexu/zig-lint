const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const rules = @import("../rules.zig");

pub const apply_for = [_]Node.Id{
    .VarDecl,
    .FnProto,
};

pub fn apply(node: *Node) rules.ApplyError!void {
    if (node.cast(Node.VarDecl)) |var_decl| {

        return;
    } else if (node.cast(Node.FnProto)) |fn_decl| {
        if (fn_decl.name_token == null) return;

        return;
    }
    unreachable;
}
