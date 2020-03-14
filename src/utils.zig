const std = @import("std");
const zig = std.zig;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const mem = std.mem;
const eql = mem.eql;

pub fn isType(tree: *Tree, node: *Node) bool {
    switch (node.id) {
        .ErrorType, .AnyFrameType, .ErrorSetDecl, .VarType => return true,
        .ContainerDecl => {
            // TODO check for namespace
            return true;
        },
        .BuiltinCall => {
            const builtin = @fieldParentPtr(Node.BuiltinCall, "base", node);
            const name = tree.tokenSlice(builtin.builtin_token);
            return eql(u8, name, "@TypeOf") or
                eql(u8, name, "@Vector") or
                eql(u8, name, "@Frame") or
                eql(u8, name, "@OpaqueType") or
                eql(u8, name, "@TagType") or
                eql(u8, name, "@This") or
                eql(u8, name, "@Type");
        },
        .InfixOp => {
            const infix = @fieldParentPtr(Node.InfixOp, "base", node);
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
            return eql(u8, name, "void") or
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
                eql(u8, name, "c_ulonglong");
        },
        else => return false,
    }
}
