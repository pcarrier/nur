const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nur = b.addExecutable(.{
        .name = "nur",
        .root_source_file = .{ .path = "src/nur.zig" },
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

    nur.addIncludePath("deps/quickjs");
    nur.linkLibrary(quickjs);

    nur.addIncludePath("deps/liblmdb");
    nur.linkLibrary(lmdb);

    nur.linkSystemLibrary("libcurl");
    nur.linkSystemLibrary("libuv");

    b.installArtifact(nur);

    const run_cmd = b.addRunArtifact(nur);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    for (&[_][]const u8{ "src/curl.zig", "src/dirs.zig", "src/lmdb.zig", "src/nur.zig", "src/quickjs.zig" }) |path| {
        const t = b.addTest(.{
            .root_source_file = .{ .path = path },
            .target = target,
            .optimize = optimize,
        });

        t.addIncludePath("deps/quickjs");
        t.linkLibrary(quickjs);

        t.addIncludePath("deps/liblmdb");
        t.linkLibrary(lmdb);

        test_step.dependOn(&t.step);
    }
}
