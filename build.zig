const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "ZigxGo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lua_dep = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
        .lang = .lua54,
        .shared = false,
    });
    exe.linkLibC();
    exe.addIncludePath(b.path("src"));
    exe.addIncludePath(b.path("src/headers"));
    exe.linkSystemLibrary("pthread");
    //exe.addObjectFile(b.path("src/LIBS/main.a"));
    exe.addObjectFile(b.path("src/LIBS/server.a"));
    exe.root_module.addImport("zlua", lua_dep.module("zlua"));
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_step.dependOn(&run_cmd.step);
}
