const std = @import("std");
const testing = std.testing;

pub fn cipherBuffer(buffer: []const u8, token: []const u8, allocator: std.mem.Allocator) ![]const u9 {
    var buf_out: []u9 = try allocator.alloc(u9, buffer.len);

    for (buffer, 0..) |chr, i| {
        buf_out[i] = @as(u9, chr) + @as(u9, token[i]);
    }

    return buf_out;
}

pub fn decipherBuffer(buffer: []const u9, token: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var buf_out: []u8 = try allocator.alloc(u8, buffer.len);

    for (buffer, 0..) |chr, i| {
        buf_out[i] = @intCast(chr - token[i]);
    }
    return buf_out;
}

pub fn octalEncode(in: []const u9, out: *std.ArrayList(u8)) !void {
    // each u16 is converted to []u8 and concatenated to 'out' ArrayList
    // each []u8 is separated by 0.
    for (in) |n| {
        var nb: u9 = n;
        var res = [_]u8{ 0, 0, 0 };
        for (0..3) |i| {
            res[i] = @intCast(nb % 8);
            nb = nb / 8;
        }
        try out.appendSlice(&res);
    }
    // std.debug.print("{any}\n", .{out.items});
}

pub fn octalDecode(in: []const u8, out: *std.ArrayList(u9)) !void {
    var i: usize = 0;
    while (i <= in.len - 3) : (i += 3) {
        var nb: u9 = 0;
        for (0..3) |j| {
            // std.debug.print("{any} x 8 ** {any}\n", .{ in[i + j], j });
            nb += in[i + j] * std.math.pow(u9, 8, @intCast(j));
        }
        try out.append(nb);
    }
}

test "octal encoding" {
    const origin = try testing.allocator.alloc(u9, 511);
    defer testing.allocator.free(origin);
    var x: u9 = 0;
    while (x <= 510) : (x += 1) {
        origin[x] = x;
    }
    var enc_arr = std.ArrayList(u8).init(testing.allocator);
    defer enc_arr.deinit();
    try octalEncode(origin, &enc_arr);
    // std.debug.print("{any}\n", .{enc_arr.items});
    var dec_arr = std.ArrayList(u9).init(testing.allocator);
    defer dec_arr.deinit();
    try octalDecode(enc_arr.items, &dec_arr);
    std.debug.print("In: {any}\nOut: {any}\n", .{ origin, dec_arr.items });
    std.debug.print("In Length: {any}\nOut Length: {any}\n", .{ origin.len, dec_arr.items.len });
    try testing.expect(origin.len == dec_arr.items.len);
    for (dec_arr.items, 0..) |item, i| {
        try testing.expect(item == origin[i]);
    }
}

// test "ciphering buffer" {
// try testing.expect(add(3, 7) == 10);
// }
