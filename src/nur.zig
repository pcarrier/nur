const std = @import("std");
const lmdb = @import("lmdb.zig");
const quickjs = @import("quickjs.zig");

const LICENSE = @embedFile("LICENSE.md");

pub fn main() !void {
    var alloc = std.heap.c_allocator;
    const path = try std.fs.getAppDataDir(alloc, "tools.nur");
    try std.fs.cwd().makePath(path);

    const env = try lmdb.Environment.init(path, .{});
    defer env.deinit();

    const rt = quickjs.Runtime.init();
    defer rt.deinit();

    const ctx = quickjs.Context.init(rt);
    defer ctx.deinit();

    try help();
}

fn help() !void {
    const writer = std.io.getStdErr().writer();
    try writer.writeAll(LICENSE);
}
