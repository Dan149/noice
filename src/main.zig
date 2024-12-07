const std = @import("std");
const root = @import("./root.zig");
const zarginator = @import("zarginator");

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
    const eql = std.mem.eql;

    const allocator = std.heap.page_allocator;
    const args = try zarginator.Args.init(allocator);

    var work_mode: ?work_modes = null;
    var in_file: ?[]const u8 = null;
    var token_file: ?[]const u8 = null;

    if (args.args.len == 0 and args.flags.len == 0) {
        return;
    }

    for (args.flags) |f| {
        if (eql(u8, f.flag, "-d")) {
            work_mode = .decipher;
        } else if (eql(u8, f.flag, "-c")) {
            work_mode = .cipher;
        } else if (eql(u8, f.flag, "-g")) {
            work_mode = .generate_token;
        } else if (eql(u8, f.flag, "-t")) {
            if (f.value) |v| {
                token_file = v;
            } else {
                try stdout.print("Error: No token file specified after -t flag.\n", .{});
            }
        } else if (eql(u8, f.flag, "-h")) {
            try stdout.print("{s}", .{HELP_MESSAGE});
        } else {
            try stdout.print("Error: invalid flag: {s}, type 'noice -h' for help.\n", .{f.flag});
            return;
        }
    }
    if (args.args.len > 0) {
        if (args.args.len != 1) {
            try stdout.print("Error: Too many arguments.\n", .{});
            return;
        }
        in_file = args.args[0];
    } else {
        if (args.flags[args.flags.len - 1].value) |v| {
            in_file = v;
        } else {
            try stdout.print("Error: input file not provided.\n", .{});
        }
    }

    var file_content: []const u8 = undefined;
    var token: []const u8 = undefined;
    defer allocator.free(file_content);

    if (in_file) |filename| {
        file_content = readFile(filename, allocator) catch {
            try stdout.print("Error: Failed to read input file.\n", .{});
            return;
        };
    } else {
        try stdout.print("Error: No input file specified.\n", .{});
        return;
    }

    if (token_file) |filename| {
        token = readFile(filename, allocator) catch {
            try stdout.print("Error: Failed to read token file.\n", .{});
            return;
        };
    } else if (work_mode != .generate_token) {
        try stdout.print("Error: No token file specified\n", .{});
        return;
    }

    if (file_content.len != token.len and work_mode == .cipher) {
        try stdout.print("Error: Token is not the same size as input file.\n", .{});
        return;
    }

    if (work_mode) |mode| {
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
                // TODO: set time-based file names.
                const of = try std.fs.cwd().createFile("decoded_data.otpraw", .{});
                defer of.close();
                try of.writeAll(d_buf);
                try stdout.print("Done!\n", .{});
            },
            .generate_token => {
                try stdout.print("Starting token generation...\n", .{});
                const new_token = try root.generateToken(file_content.len, allocator);
                defer allocator.free(new_token);
                // TODO: set time-based file names.
                const of = try std.fs.cwd().createFile("token.otptok", .{});
                defer of.close();
                try of.writeAll(new_token);
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

const work_modes = enum { cipher, decipher, generate_token };
