const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const tests_step = b.step("test", "Run all tests");
    tests_step.dependOn(b.getInstallStep());

    var tests = b.addTest("src/main.zig");
    tests.setBuildMode(mode);
    tests_step.dependOn(&tests.step);

    var exe = b.addExecutable("lint", "src/main.zig");
    exe.setBuildMode(mode);
    exe.install();
    exe.linkLibC();

    const fmt_step = b.step("fmt", "Format all source files");
    fmt_step.dependOn(&b.addFmt(&[_][]const u8{ "build.zig", "src" }).step);
}
