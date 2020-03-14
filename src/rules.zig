const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const linter = @import("linter.zig");
const Linter = linter.Linter;
const Message = linter.Message;

pub const ApplyError = error{} || std.mem.Allocator.Error;

/// Function to apply rule.
pub const ApplyFn = fn (*Linter, *Tree, *Node) ApplyError!?Message;

/// Rule with a set of node id's to apply it to.
pub const Rule = struct {
    apply_for: []const Node.Id,
    apply: ApplyFn,
    name: []const u8,
};

fn makeRule(comptime name: []const u8) Rule {
    const rule = @import("rules/" ++ name ++ ".zig");

    if (!@hasDecl(rule, "apply")) @compileError("rule has no `apply` function");
    if (@TypeOf(rule.apply) != ApplyFn) @compileError("invalid apply function");

    if (!@hasDecl(rule, "apply_for")) @compileError("rule has no `apply_for` variable");
    const ArrT = @typeInfo(@TypeOf(rule.apply_for));
    if (ArrT != .Array or ArrT.Array.child != Node.Id) @compileError("invalid apply_for array");

    return .{
        .apply_for = rule.apply_for[0..],
        .apply = rule.apply,
        .name = name,
    };
}

const rules = [_]Rule{
    makeRule("declaration_names"),
    makeRule("non_canonic_name"),
};

pub fn byId(id: Node.Id) []const Rule {
    inline for (std.meta.fields(Node.Id)) |field| {
        if (@field(Node.Id, field.name) == id) {
            return comptime ruleArr(@field(Node.Id, field.name));
        }
    }
    unreachable;
}

fn ruleArr(comptime id: Node.Id) []const Rule {
    var rule_arr: []const Rule = &[_]Rule{};
    rules: for (rules) |rule| {
        for (rule.apply_for) |rule_id| {
            if (rule_id == id) {
                rule_arr = rule_arr ++ &[_]Rule{rule};
                continue :rules;
            }
        }
    }
    return rule_arr;
}
