const std = @import("std");
const zig = std.zig;
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;
const Node = zig.ast.Node;
const Tree = zig.ast.Tree;
const Options = @import("main.zig").Options;

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

    pub fn lintPath(self: *Linter, path: []const u8, stream: var) !void {
        // TODO make this async when https://github.com/ziglang/zig/issues/3777 is fixed
        if (self.seen.contains(path)) return;
        try self.seen.put(path);

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
                        try self.lintPath(full_path);
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
            try stderr.print("error parsing file '{}': {}\n", .{ path, err });
            self.errors = true;
            return;
        };
        defer tree.deinit();

        var error_it = tree.errors.iterator(0);
        if (tree.errors.len != 0) {
            self.errors = true;
            @panic("TODO print errors");
        }

        try self.lintNode(tree, &tree.root_node.base, stream);
    }

    fn lintNode(self: *Linter, tree: *Tree, node: *Node, stream: var) !void {}
};
