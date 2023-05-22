const std = @import("std");
const lmdb = @import("lmdb.zig");
const quickjs = @import("quickjs.zig");

pub fn main() !void {
    const db = lmdb.Environment.init(".nur", .{});
    defer db.deinit();
    const rt = quickjs.Runtime.init();
    defer rt.deinit();
    const ctx = quickjs.Context.init(rt);
    defer ctx.deinit();
}
