const std = @import("std");
const c = std.c;
const Lua = @import("zlua").Lua;
const goServer = @cImport({
    @cInclude("headers/server.h");
});

const dprint = std.debug.print;

pub fn main() !void {
    std.io.getStdOut().writeAll(
        "Hello World!\n",
    ) catch unreachable;

    //allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    dprint("ALLOCATORS ARE SET UP\n", .{});

    //Server Setup
    const errCode: c_int = goServer.ServerInit(8090);

    if (errCode != 1) {
        dprint("SERVER INIT ERROR: {}\n", .{errCode});
        return error.ServerInitError;
    }
    defer goServer.ServerClose();
    dprint("SERVER IS SET UP\n", .{});

    // Initialize the Lua vm
    var lua = try Lua.init(allocator);
    defer lua.deinit();
    std.debug.print("LUA IS SET UP\n", .{});

    //load Lua Files
    const files = printAllLuaScripts(".\\src\\scripts");
    defer files.deinit();

    // Add an integer to the Lua stack and retrieve it
    lua.pushInteger(42);
    dprint("{}\n", .{try lua.toInteger(1)});
    var inputBuff: [1024]u8 = undefined;

    while (true) {
        const bytesRead = try std.io.getStdIn().read(&inputBuff);
        if (bytesRead == 0) break;

        // Ensure we check only the bytes that were actually read
        const input = inputBuff[0..bytesRead];
        dprint("Read {} bytes: {s}\n", .{ bytesRead, input });
        if (std.mem.eql(u8, std.mem.trim(u8, input, &std.ascii.whitespace), "exit")) {
            break;
        }

        // Push the string to Lua with correct length
        _ = lua.pushString(input);
    }

    //server setup
    //goServer.ReadInput();
}

fn ReadCurrentDir() !void {
    //code from https://dayvster.com/blog/read-directory-contents-with-zig/
    // Define the allocator
    const allocator = std.heap.page_allocator;

    // Open the current working directory as an iterable directory
    var dir = std.fs.cwd().openDir(".\\src\\scripts", .{ .iterate = true }) catch |err| {
        std.debug.print("Failed to open directory: {}\n", .{err});
        return err;
    };
    defer dir.close();

    // Create an ArrayList to hold the file names
    var file_list = std.ArrayList([]const u8).init(allocator);
    defer file_list.deinit();

    // Iterate through the directory contents
    var dirIterator = dir.iterate();
    while (dirIterator.next() catch |err| {
        std.debug.print("Error during directory iteration: {}\n", .{err});
        return err;
    }) |dirContent| {
        // Append the file name to the ArrayList
        try file_list.append(dirContent.name);
    }

    // Print the contents of the ArrayList
    const stdout = std.io.getStdOut().writer();
    try stdout.print("--- Directory Contents ---\n", .{});
    for (file_list.items) |file_name| {
        try stdout.print("File: {s}\n", .{file_name});
    }
}

fn printAllLuaScripts(dirPath: []const u8) std.ArrayList([]const u8) {
    const dirAllocator = std.heap.page_allocator;
    var luaFiles = std.ArrayList([]const u8).init(dirAllocator);
    defer luaFiles.deinit();

    dprint("LOOKING FOR FILES IN: {s}\n", .{dirPath});
    var openDir = std.fs.cwd().openDir(dirPath, .{ .iterate = true }) catch {
        dprint("ERROR OPENING DIR: {s}\n", .{dirPath});
        return luaFiles;
    };
    defer openDir.close();

    // Iterate through the directory contents
    var dirIterator = openDir.iterate();
    while (dirIterator.next() catch |err| {
        std.debug.print("Error during directory iteration: {}\n", .{err});
        return luaFiles;
    }) |dirContent| {
        if (std.mem.endsWith(u8, dirContent.name, ".lua"))
            dprint("FOUND: {s}", .{dirContent.name});
        luaFiles.append(dirContent.name) catch |err| {
            std.debug.print("Error appending to ArrayList: {}\n", .{err});
            return luaFiles;
        };
    }
    return luaFiles;
}
