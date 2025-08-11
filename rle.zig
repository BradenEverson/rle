//! Run Length Encoding Method, very good for when you have a lot of repeating stuff

const std = @import("std");

pub fn EncodePair(comptime T: type) type {
    return struct {
        val: T,
        times: u8,
    };
}

pub fn rleToBytes(encode: []const EncodePair(u8), target: *std.ArrayList(u8)) !void {
    for (encode) |pair| {
        try target.append(pair.val);
        try target.append(pair.times);
    }
}

pub fn bytesToRle(bytes: []const u8, to: *std.ArrayList(EncodePair(u8))) !void {
    for (bytes, 0..) |val, i| {
        if (i % 2 == 0) {
            try to.append(.{
                .val = val,
                .times = bytes[i + 1],
            });
        }
    }
}

pub fn runLengthDecode(encode: []const EncodePair(u8), target: *std.ArrayList(u8)) !void {
    for (encode) |pair| {
        for (0..pair.times) |_| {
            try target.append(pair.val);
        }
    }
}

pub fn runLengthEncode(comptime T: type, msg: []const T, encode_to: *std.ArrayList(EncodePair(T))) !void {
    if (msg.len == 0) {
        return;
    }

    var count: u8 = 1;
    var curr = msg[0];

    for (msg[1..]) |item| {
        if (item != curr or count == std.math.maxInt(u8)) {
            try encode_to.append(.{
                .val = curr,
                .times = count,
            });

            curr = item;
            count = 1;
        } else {
            count += 1;
        }
    }

    try encode_to.append(.{
        .val = curr,
        .times = count,
    });
}

test "Simple RLE" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var encode_to = std.ArrayList(EncodePair(u8)).init(alloc);
    defer encode_to.deinit();

    try runLengthEncode(u8, "aaaa", &encode_to);

    try std.testing.expectEqual(EncodePair(u8){ .val = 'a', .times = 4 }, encode_to.items[0]);
}

test "Crazier RLE" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var encode_to = std.ArrayList(EncodePair(u8)).init(alloc);
    defer encode_to.deinit();

    try runLengthEncode(u8, "aaaaabbb000llllll", &encode_to);

    try std.testing.expectEqualSlices(EncodePair(u8), &[_]EncodePair(u8){
        .{ .val = 'a', .times = 5 },
        .{ .val = 'b', .times = 3 },
        .{ .val = '0', .times = 3 },
        .{ .val = 'l', .times = 6 },
    }, encode_to.items);
}

test "Max u8 size" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var encode_to = std.ArrayList(EncodePair(u8)).init(alloc);
    defer encode_to.deinit();

    try runLengthEncode(u8, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", &encode_to);

    try std.testing.expectEqualSlices(EncodePair(u8), &[_]EncodePair(u8){
        .{ .val = 'a', .times = 255 },
        .{ .val = 'a', .times = 1 },
    }, encode_to.items);
}

test "Decode" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var decoded = std.ArrayList(u8).init(alloc);
    defer decoded.deinit();
    var decoded_rle = std.ArrayList(EncodePair(u8)).init(alloc);
    defer decoded_rle.deinit();

    const encoded = &[_]u8{ 'a', 5, 'b', 2 };

    try bytesToRle(encoded, &decoded_rle);
    try runLengthDecode(decoded_rle.items, &decoded);

    try std.testing.expectEqualSlices(u8, "aaaaabb", decoded.items);
}
