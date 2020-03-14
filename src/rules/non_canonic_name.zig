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

const non_canonic = "non-canonical identifier";

pub fn apply(linter: *Linter, tree: *Tree, node: *Node) rules.ApplyError!?Message {
    var name_tok: zig.ast.TokenIndex = undefined;
    if (node.cast(Node.VarDecl)) |var_decl| {
        name_tok = var_decl.name_token;
    } else if (node.cast(Node.FnProto)) |fn_decl| {
        name_tok = fn_decl.name_token orelse return null;
    } else unreachable;

    const name = tree.tokenSlice(name_tok);
    if (name[0] != '@') return null;

    // TODO use parse_string_literal when https://github.com/ziglang/zig/pull/4678 lands

    var i: usize = 2;
    while (i < name.len - 1) : (i += 1) {
        switch (name[i]) {
            'a'...'z', '_', '0'...'9', 'A'...'Z' => {},
            else => return null,
        }
    }
    return Message.fromToken(non_canonic, name_tok);
}
