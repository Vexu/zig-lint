const std = @import("std");
const rules = @import("rules.zig");
const Linter = @import("linter.zig").Linter;
const argsParser = @import("arg-parser");

pub const Options = struct {
    color: bool = true,
};

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const stderr = std.io.getStdErr().outStream();

    const args = argsParser.parseForCurrentProcess(Options, alloc) catch
        std.process.exit(1);
    defer args.deinit();

    if (args.positionals.len < 1) {
        try stderr.writeAll("expected input files\n\n");
        std.process.exit(1);
    }

    var linter = Linter.init(alloc, args.options);
    defer linter.deinit();

    for (args.positionals) |path| {
        try linter.lintPath(path, stderr);
    }

    if (linter.errors) {
        std.process.exit(1);
    }
}
