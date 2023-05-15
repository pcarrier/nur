const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nur = b.addExecutable(.{
        .name = "nur",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const quickjs = b.addStaticLibrary(.{
        .name = "quickjs",
        .target = target,
        .optimize = optimize,
    });
    quickjs.linkLibC();
    quickjs.addCSourceFiles(&[_][]const u8{
        "deps/quickjs/cutils.c",
        "deps/quickjs/libbf.c",
        "deps/quickjs/libregexp.c",
        "deps/quickjs/libunicode.c",
        "deps/quickjs/quickjs.c",
    }, &[_][]const u8{
        "-Wall",
        "-Wextra",
        "-DCONFIG_BIGNUM",
        "-DCONFIG_VERSION=\"2021-03-27\"",
    });
    nur.addIncludePath("deps/quickjs");
    nur.linkLibrary(quickjs);

    const lmdb = b.addStaticLibrary(.{
        .name = "lmdb",
        .target = target,
        .optimize = optimize,
    });
    lmdb.linkLibC();
    lmdb.addCSourceFiles(&[_][]const u8{
        "deps/liblmdb/mdb.c",
        "deps/liblmdb/midl.c",
    }, &[_][]const u8{
        "-Wall",
        "-Wextra",
    });
    nur.addIncludePath("deps/liblmdb");
    nur.linkLibrary(lmdb);

    nur.linkSystemLibrary("curl");

    b.installArtifact(nur);

    const run_cmd = b.addRunArtifact(nur);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
