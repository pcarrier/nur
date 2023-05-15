const std = @import("std");
const quickjs = @cImport(@cInclude("quickjs.h"));
const lmdb = @cImport(@cInclude("lmdb.h"));
const curl = @cImport(@cInclude("curl/curl.h"));

pub fn main() !void {
    var env: ?*lmdb.MDB_env = null;
    _ = lmdb.mdb_env_create(&env);
    defer _ = lmdb.mdb_env_close(env);
    _ = lmdb.mdb_env_open(env, ".nur", 0, 0o664);
    var rt = quickjs.JS_NewRuntime();
    defer quickjs.JS_FreeRuntime(rt);
    var ctx = quickjs.JS_NewContext(rt);
    defer quickjs.JS_FreeContext(ctx);
}
