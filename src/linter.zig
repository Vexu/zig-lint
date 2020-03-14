const std = @import("std");
const zig = std.zig;
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const TokenIndex = zig.ast.TokenIndex;
const Options = @import("main.zig").Options;
const rules = @import("rules.zig");

pub const Message = struct {
    msg: []const u8,
    span: struct {
        begin: TokenIndex,
        end: TokenIndex,
    },

    pub fn fromToken(msg: []const u8, tok: TokenIndex) Message {
        return .{
            .msg = msg,
            .span = .{
                .begin = tok,
                .end = tok,
            },
        };
    }

    fn print(self: Message, path: []const u8, tree: *Tree, stream: var) !void {
        const RED = "\x1b[31;1m";
        const BOLD = "\x1b[0;1m";
        const RESET = "\x1b[0m";

        const first_token = tree.tokens.at(self.span.begin);
        const last_token = tree.tokens.at(self.span.end);
        const loc = tree.tokenLocationPtr(0, first_token);

        const prefix = if (!std.fs.path.isAbsolute(path)) "./" else "";
        try stream.print(
            BOLD ++ "{}{}:{}:{}: " ++ RED ++ "error: " ++ BOLD ++ "{}" ++ RESET ++ "\n{}\n",
            .{
                prefix,
                path,
                loc.line + 1,
                loc.column + 1,
                self.msg,
                tree.source[loc.line_start..loc.line_end],
            },
        );
        try stream.writeByteNTimes(' ', loc.column);
        try stream.writeAll(RED);
        try stream.writeByteNTimes('~', last_token.end - first_token.start);
        try stream.writeAll(RESET ++ "\n");
    }
};

pub const Linter = struct {
    allocator: *Allocator,
    seen: PathMap,
    options: Options,
    errors: bool = false,

    const PathMap = std.StringHashMap(void);

    pub fn init(allocator: *Allocator, options: Options) Linter {
        return .{
            .options = options,
            .allocator = allocator,
            .seen = PathMap.init(allocator),
        };
    }

    pub fn deinit(self: *Linter) void {
        self.seen.deinit();
    }

    pub const LintError = error{} || rules.ApplyError || std.os.WriteError || std.fs.Dir.OpenError;

    pub fn lintPath(self: *Linter, path: []const u8, stream: var) LintError!void {
        // TODO make this async when https://github.com/ziglang/zig/issues/3777 is fixed
        if (self.seen.contains(path)) return;
        try self.seen.putNoClobber(path, {});

        const source_code = std.io.readFileAlloc(self.allocator, path) catch |err| switch (err) {
            error.IsDir, error.AccessDenied => {
                var dir = try fs.cwd().openDirList(path);
                defer dir.close();

                var it = dir.iterate();
                while (try it.next()) |entry| {
                    if (entry.kind == .Directory or mem.endsWith(u8, entry.name, ".zig")) {
                        const full_path = try fs.path.join(
                            self.allocator,
                            &[_][]const u8{ path, entry.name },
                        );
                        try self.lintPath(full_path, stream);
                    }
                }
                return;
            },
            else => {
                try stream.print("unable to open '{}': {}\n", .{ path, err });
                self.errors = true;
                return;
            },
        };
        defer self.allocator.free(source_code);

        const tree = zig.parse(self.allocator, source_code) catch |err| {
            try stream.print("error parsing file '{}': {}\n", .{ path, err });
            self.errors = true;
            return;
        };
        defer tree.deinit();

        var error_it = tree.errors.iterator(0);
        if (tree.errors.len != 0) {
            self.errors = true;
            @panic("TODO print errors");
        }

        try self.lintNode(path, tree, &tree.root_node.base, stream);
    }

    fn lintNode(self: *Linter, path: []const u8, tree: *Tree, node: *Node, stream: var) LintError!void {
        const node_rules = rules.byId(node.id);

        for (node_rules) |rule| {
            if (try rule.apply(self, tree, node)) |some| {
                self.errors = true;
                try some.print(path, tree, stream);
            }
        }

        var i: usize = 0;
        while (node.iterate(i)) |child| : (i += 1) {
            try self.lintNode(path, tree, child, stream);
        }
    }
};
