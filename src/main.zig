const std = @import("std");
//const dprint = std.debug.print;
const goMain = @cImport({
    @cInclude("headers/main.h");
    @cInclude("headers/server.h");
});
pub fn main() !void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;
    goMain.ServerInit(8090);
    defer goMain.ServerClose();

    goMain.ReadInput();
}
