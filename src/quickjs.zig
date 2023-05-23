const c = @cImport(@cInclude("quickjs.h"));

pub const Runtime = packed struct {
    const Self = @This();

    inner: ?*c.JSRuntime,

    pub inline fn init() Self {
        return Self{ .inner = c.JS_NewRuntime() };
    }

    pub inline fn deinit(self: Self) void {
        c.JS_FreeRuntime(self.inner);
    }
};

pub const Context = packed struct {
    const Self = @This();

    inner: ?*c.JSContext,

    pub inline fn init(rt: Runtime) Self {
        return Self{ .inner = c.JS_NewContext(rt.inner) };
    }

    pub inline fn deinit(self: Self) void {
        c.JS_FreeContext(self.inner);
    }
};
