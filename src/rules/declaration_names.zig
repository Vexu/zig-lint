const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const rules = @import("../rules.zig");
const utils = @import("../utils.zig");
const Linter = @import("../linter.zig").Linter;

pub const apply_for = [_]Node.Id{
    .VarDecl,
    .FnProto,
};

pub fn apply(linter: *Linter, tree: *Tree, node: *Node) rules.ApplyError!void {
    if (node.cast(Node.VarDecl)) |var_decl| {
        const is_type = var_decl.init_node == null or
            utils.isType(tree, var_decl.init_node.?);

        return;
    } else if (node.cast(Node.FnProto)) |fn_decl| {
        if (fn_decl.name_token == null) return;
        const return_type = switch (fn_decl.return_type) {
            .Explicit => |ret_node| ret_node,
            .InferErrorSet => |ret_node| ret_node,
        };
        const is_type = utils.isType(tree, return_type);

        return;
    }
    unreachable;
}
