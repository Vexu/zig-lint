const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;

pub const ApplyError = error{
// foo
} || std.mem.Allocator.Error;

/// Function to apply rule.
pub const ApplyFn = fn (*Node) ApplyError!void;

/// Rule with a set of node id's to apply it to.
pub const Rule = struct {
    apply_for: []const Node.Id,
    apply: ApplyFn,
};

fn makeRule(rule: var) Rule {
    if (!@hasDecl(rule, "apply")) @compileError("rule has no `apply` function");
    if (@TypeOf(rule.apply) != ApplyFn) @compileError("invalid apply function");

    if (!@hasDecl(rule, "apply_for")) @compileError("rule has no `apply_for` variable");
    const ArrT = @typeInfo(@TypeOf(rule.apply_for));
    if (ArrT != .Array or ArrT.Array.child != Node.Id) @compileError("invalid apply_for array");

    return .{
        .apply_for = rule.apply_for[0..],
        .apply = rule.apply,
    };
}

pub const rules = [_]Rule{
    makeRule(@import("rules/declaration_names.zig")),
};
