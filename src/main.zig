const std = @import("std");
const c = std.c;
//const dprint = std.debug.print;
const goMain = @cImport({
    @cInclude("headers/main.h");
    @cInclude("headers/server.h");
});
const zlua = @import("zlua");

const Lua = zlua.Lua;
pub fn main() !void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    std.debug.print("ALLOCATORS ARE SET UP\n", .{});
    const errCode: c_int = goMain.ServerInit(8090);

    if (errCode != 1) {
        std.debug.print("SERVER INIT ERROR: {}\n", .{errCode});
        return error.ServerInitError;
    }
    defer goMain.ServerClose();
    std.debug.print("SERVER IS SET UP\n", .{});
    // Initialize the Lua vm
    var lua = try Lua.init(allocator);
    defer lua.deinit();
    std.debug.print("LUA IS SET UP\n", .{});
    // Add an integer to the Lua stack and retrieve it
    lua.pushInteger(42);
    std.debug.print("{}\n", .{try lua.toInteger(1)});

    goMain.ReadInput();
}
