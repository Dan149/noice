const std = @import("std");
const root = @import("./root.zig");

const HELP_MESSAGE =
    \\noice - one-time pad encryption CLI tool
    \\noice [OPTIONS] <file>
    \\
    \\[OPTIONS]:
    \\
    \\-c                            | set work mode to cipher
    \\-d                            | set work mode to decipher
    \\-g                            | set work mode to token generation
    \\-t=<token file>               | set token file to use
    \\-C                            | cipher & generate token
    \\
    \\Reminder:
    \\
    \\OTP is an unhackable method of encryption as long as the following rules are followed:
    \\  - The token is fully random.
    \\  - The token stays secret from any third parties.
    \\
    \\ Obviously, the effectiveness of this method is proportional to your ability to store your tokens safely.
    \\
    \\ ---
    \\
    \\May god be with you,
    \\ DF.
    \\
;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const allocator = std.heap.page_allocator;

    var args: std.process.ArgIterator = std.process.args();
    var workMode: ?WorkModes = null;
    var in_file: ?[]const u8 = null;
    var token_file: ?[]const u8 = null;
    _ = args.next();

    while (args.next()) |arg| {
        var flag: bool = false;
        for (arg, 0..) |chr, i| {
            switch (i) {
                0 => {
                    if (chr == '-') {
                        flag = true;
                    }
                },
                1 => {
                    if (flag) {
                        switch (chr) {
                            'c' => workMode = .cipher,
                            'd' => workMode = .decipher,
                            't' => {
                                token_file = arg[3..];
                                break;
                            },
                            'h' => {
                                try stdout.print("{s}", .{HELP_MESSAGE});
                                return;
                            },
                            // TODO: Add -g flag support.
                            // TODO: Add -C flag support.
                            else => {
                                try stdout.print("Error: Unknown flag: {c}\n", .{chr});
                                return;
                            },
                        }
                    }
                },
                else => {
                    if (flag) {
                        try stdout.print("noice [OPTIONS] <in_file>\n", .{});
                        return;
                    }
                },
            }
        }
        if (!flag) {
            in_file = arg;
        }
    }

    var file_content: []const u8 = undefined;
    var token: []const u8 = undefined;
    defer allocator.free(file_content);

    if (in_file) |filename| {
        file_content = readFile(filename, allocator) catch {
            @panic("Error: Failed to read input file.\n");
        };
    } else {
        @panic("Error: No input file specified.\n");
    }

    if (token_file) |filename| {
        token = readFile(filename, allocator) catch {
            @panic("Error: Failed to read token file.\n");
        };
    } else {
        @panic("Error: No token file specified (-t=<filename>).\n");
    }

    if (file_content.len != token.len and workMode == .cipher) {
        @panic("Error: Token is not the same size as input file.\n");
    }

    if (workMode) |mode| {
        switch (mode) {
            .cipher => {
                try stdout.print("Starting file ciphering...\n", .{});
                var arr_buf = std.ArrayList(u8).init(allocator);
                defer arr_buf.deinit();
                const c_buf = try root.cipherBuffer(file_content, token, allocator);
                try root.octalEncode(c_buf, &arr_buf);
                allocator.free(c_buf);

                var filename: []u8 = try allocator.alloc(u8, in_file.?.len + 7);
                defer allocator.free(filename);
                for (in_file.?, 0..) |chr, i| {
                    filename[i] = chr;
                }
                for (".otpenc", in_file.?.len..in_file.?.len + 7) |chr, i| {
                    filename[i] = chr;
                }
                const of = try std.fs.cwd().createFile(filename, .{});
                defer of.close();
                try of.writeAll(arr_buf.items);
                try stdout.print("Done!\n", .{});
            },
            .decipher => {
                try stdout.print("Starting file deciphering...\n", .{});
                var decoded_arr = std.ArrayList(u9).init(allocator);
                try root.octalDecode(file_content, &decoded_arr);
                const d_buf = try root.decipherBuffer(decoded_arr.items, token, allocator);
                defer allocator.free(d_buf);
                decoded_arr.deinit();
                const of = try std.fs.cwd().createFile("decoded_data.otpraw", .{});
                defer of.close();
                try of.writeAll(d_buf);
                try stdout.print("Done!\n", .{});
            },
        }
    } else {
        @panic("Error: No working mode provided:\n-c (cipher)/-d (decipher)/-g (generate token).\n");
    }
}

fn readFile(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    return std.fs.cwd().readFileAlloc(allocator, filename, 1_000_000_000);
}

const WorkModes = enum { cipher, decipher };
