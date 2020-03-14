const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const mem = std.mem;
const eql = mem.eql;

/// null if cannot be determined
pub fn isType(tree: *Tree, node: *Node) ?bool {
    switch (node.id) {
        .ErrorType, .AnyFrameType, .ErrorSetDecl, .VarType => return true,
        .ContainerDecl => {
            // TODO check for namespace
            return true;
        },
        .BuiltinCall => {
            const builtin = @fieldParentPtr(Node.BuiltinCall, "base", node);
            const name = tree.tokenSlice(builtin.builtin_token);
            if (eql(u8, name, "@import")) return null;
            return eql(u8, name, "@TypeOf") or
                eql(u8, name, "@Vector") or
                eql(u8, name, "@Frame") or
                eql(u8, name, "@OpaqueType") or
                eql(u8, name, "@TagType") or
                eql(u8, name, "@This") or
                eql(u8, name, "@Type") or
                eql(u8, name, "@typeInfo");
        },
        .InfixOp => {
            const infix = @fieldParentPtr(Node.InfixOp, "base", node);
            if (infix.op == .Period) return null;
            return infix.op == .ErrorUnion or
                infix.op == .MergeErrorSets;
        },
        .PrefixOp => {
            const prefix = @fieldParentPtr(Node.PrefixOp, "base", node);
            switch (prefix.op) {
                .ArrayType,
                .OptionalType,
                .PtrType,
                .SliceType,
                => return true,
                else => return false,
            }
        },
        .SuffixOp => {
            const suffix = @fieldParentPtr(Node.SuffixOp, "base", node);
            if (suffix.op == .Call) return null;
            return false;
        },
        .FnProto => {
            const proto = @fieldParentPtr(Node.FnProto, "base", node);
            return proto.body_node == null;
        },
        .GroupedExpression => {
            const group = @fieldParentPtr(Node.GroupedExpression, "base", node);
            return isType(tree, group.expr);
        },
        .Identifier => {
            const ident = @fieldParentPtr(Node.Identifier, "base", node);
            const name = tree.tokenSlice(ident.token);

            if (name.len > 1 and (name[0] == 'u' or name[0] == 'i')) {
                for (name[1..]) |c| {
                    switch (c) {
                        '0'...'9' => {},
                        else => return false,
                    }
                }
                return true;
            }
            if (eql(u8, name, "void") or
                eql(u8, name, "comptime_float") or
                eql(u8, name, "comptime_int") or
                eql(u8, name, "bool") or
                eql(u8, name, "isize") or
                eql(u8, name, "usize") or
                eql(u8, name, "f16") or
                eql(u8, name, "f32") or
                eql(u8, name, "f64") or
                eql(u8, name, "f128") or
                eql(u8, name, "c_longdouble") or
                eql(u8, name, "noreturn") or
                eql(u8, name, "type") or
                eql(u8, name, "anyerror") or
                eql(u8, name, "c_short") or
                eql(u8, name, "c_ushort") or
                eql(u8, name, "c_int") or
                eql(u8, name, "c_uint") or
                eql(u8, name, "c_long") or
                eql(u8, name, "c_ulong") or
                eql(u8, name, "c_longlong") or
                eql(u8, name, "c_ulonglong"))
                return true;
            return null;
        },
        else => return false,
    }
}

pub fn isSnakeCase(name: []const u8) bool {
    std.debug.assert(name.len != 0);
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        switch (name[i]) {
            'a'...'z', '0'...'9' => {},
            '_' => {
                if (i == 0 or i == name.len - 1) return false;
            },
            else => return false,
        }
    }
    return true;
}

pub fn isCamelCase(name: []const u8) bool {
    std.debug.assert(name.len != 0);
    switch (name[0]) {
        'a'...'z' => {},
        else => return false,
    }
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        switch (name[i]) {
            'a'...'z', '0'...'9', 'A'...'Z' => {},
            else => return false,
        }
    }
    return true;
}

pub fn isTitleCase(name: []const u8) bool {
    std.debug.assert(name.len != 0);
    switch (name[0]) {
        'A'...'Z' => {},
        else => return false,
    }
    var i: usize = 0;
    while (i < name.len) : (i += 1) {
        switch (name[i]) {
            'a'...'z', '0'...'9', 'A'...'Z' => {},
            else => return false,
        }
    }
    return true;
}
