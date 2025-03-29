const std = @import("std");
const dprint = std.debug.print;
const goMain = @cImport({
    @cInclude("headers/main.h");
});
pub fn main() !void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;
    goMain.PrintInt(42);
}
