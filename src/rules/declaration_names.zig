const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const rules = @import("../rules.zig");
const utils = @import("../utils.zig");
const Linter = @import("../linter.zig").Linter;
const Message = @import("../linter.zig").Message;

pub const apply_for = [_]Node.Id{
    .VarDecl,
    .FnProto,
};

const type_name = "type names must be CapitalCase";
const func_name = "function names must be camelCase";
const var_name = "variable names must be snake_case";

pub fn apply(linter: *Linter, tree: *Tree, node: *Node) rules.ApplyError!?Message {
    if (node.cast(Node.VarDecl)) |var_decl| {
        const is_type = var_decl.init_node == null or
            utils.isType(tree, var_decl.init_node.?);
        const name = tree.tokenSlice(var_decl.name_token);

        if (is_type and !utils.isTitleCase(name)) {
            return Message.fromToken(type_name, var_decl.name_token);
        } else if (!utils.isSnakeCase(name)) {
            return Message.fromToken(var_name, var_decl.name_token);
        } else {
            return null;
        }
    } else if (node.cast(Node.FnProto)) |fn_decl| {
        const name_tok = fn_decl.name_token orelse return null;
        const return_type = switch (fn_decl.return_type) {
            .Explicit => |ret_node| ret_node,
            .InferErrorSet => |ret_node| ret_node,
        };
        const is_type = if (return_type.cast(Node.Identifier)) |some|
            std.mem.eql(u8, "type", tree.tokenSlice(some.token))
        else
            false;
        const name = tree.tokenSlice(name_tok);

        if (is_type and !utils.isTitleCase(name)) {
            return Message.fromToken(type_name, name_tok);
        } else if (!utils.isCamelCase(name)) {
            return Message.fromToken(func_name, name_tok);
        } else {
            return null;
        }
    }
    unreachable;
}
