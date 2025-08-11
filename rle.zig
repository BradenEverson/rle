//! Run Length Encoding Method, very good for when you have a lot of repeating stuff

const std = @import("std");

pub fn EncodePair(comptime T: type) type {
    return struct {
        val: T,
        times: u32,
    };
}

pub fn runLengthEncode(comptime T: type, msg: []const T, encode_to: *std.ArrayList(EncodePair(T))) !void {
    if (msg.len == 0) {
        return;
    }

    var count: u32 = 1;
    var curr = msg[0];

    for (msg[1..]) |item| {
        if (item != curr) {
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
