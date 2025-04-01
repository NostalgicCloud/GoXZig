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
    lua.openLibs();
    std.debug.print("LUA IS SET UP\n", .{});

    //load Lua Files
    const files = printAllLuaScripts(".\\src\\scripts\\") catch {
        return error.LuaFileError;
    };
    defer files.deinit();

    for (files.items) |file| {
        dprint("LOADING LUA FILE: {s}\n", .{file});
        lua.doFile(file) catch |err| {
            dprint("ERROR LOADING LUA FILE: {s}, ERROR: {}\n", .{ file, err });

            // If available, print any error message from Lua
            if (lua.isString(-1)) {
                const errMsg = lua.toString(-1) catch "unknown error";
                dprint("LUA ERROR MESSAGE: {s}\n", .{errMsg});
            }
            return err;
        };
    }

    // Add an integer to the Lua stack and retrieve it
    // lua.pushInteger(42);
    // dprint("{}\n", .{try lua.toInteger(1)});
    var inputBuff: [1024]u8 = undefined;

    while (true) {
        _ = try lua.getGlobal("should_exit");
        lua.call(.{ .args = 0, .results = 1 });
        const shouldExit = lua.toBoolean(-1);
        lua.pop(1);
        if (shouldExit) {
            dprint("Goodbye.\n", .{});
            break;
        }

        const bytesRead = try std.io.getStdIn().read(&inputBuff);
        if (bytesRead == 0) break;

        // Ensure we check only the bytes that were actually read
        const input = inputBuff[0..bytesRead];
        dprint("Read {} bytes: {s}\n", .{ bytesRead, input });

        _ = try lua.getGlobal("handle_command");
        _ = lua.pushString(input);
        lua.call(.{ .args = 1, .results = 1 });

        if (lua.isString(-1)) {
            const result = lua.toString(-1) catch "Error getting result";
            dprint("Command result: {s}\n", .{result});
        } else {
            dprint("Command did not return a string\n", .{});
        }
        // Clean up the stack
        lua.pop(1);
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

fn printAllLuaScripts(dirPath: []const u8) !std.ArrayList([:0]const u8) {
    const dirAllocator = std.heap.page_allocator;
    var luaFiles = std.ArrayList([:0]const u8).init(dirAllocator);
    errdefer luaFiles.deinit();

    dprint("LOOKING FOR FILES IN: {s}\n", .{dirPath});
    var openDir = std.fs.cwd().openDir(dirPath, .{ .iterate = true }) catch {
        dprint("ERROR OPENING DIR: {s}\n", .{dirPath});
        return error.PathOpenError;
    };
    defer openDir.close();

    // Iterate through the directory contents
    var dirIterator = openDir.iterate();
    while (dirIterator.next() catch |err| {
        std.debug.print("Error during directory iteration: {}\n", .{err});
        return error.DirectoryIterationError;
    }) |dirContent| {
        if (std.mem.endsWith(u8, dirContent.name, ".lua"))
            dprint("FOUND: {s}\n", .{dirContent.name});
        luaFiles.append(concat(dirAllocator, dirPath, dirContent.name) catch {
            return error.ConcatDirectoryError;
        }) catch |err| {
            std.debug.print("Error appending to ArrayList: {}\n", .{err});
            return error.AppendDirectoryError;
        };
        dprint("{s}\n", .{luaFiles.items[0]});
    }
    return luaFiles;
}

//thanks to https://ziglang.org/documentation/0.14.0/#String-Literals-and-Unicode-Code-Point-Literals
fn concat(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![:0]u8 {
    const result = try allocator.alloc(u8, a.len + b.len + 1);
    const len = a.len + b.len;
    if (len == 0) return error.ZeroSize; // EOF
    if (len >= result.len) {
        dprint("error: line too long!\n", .{});
        return error.LineTooLong;
    }
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..len], b);
    result[len] = 0; // Null-terminate the string
    return result[0..len :0];
}
