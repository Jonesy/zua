const std = @import("std");
const testing = std.testing;

const Chars = @This();

bytes: []const u8,
index: usize = 0,
len: usize = 0,

pub fn init(bytes: []const u8) Chars {
    return Chars{
        .bytes = bytes,
        .len = bytes.len,
    };
}

pub fn next(self: *Chars) ?u8 {
    const index = self.index;
    for (self.bytes[index..]) |char| {
        self.index += 1;
        self.len = self.len - 1;
        return char;
    }
    return null;
}

pub fn take(self: *Chars, num: usize) void {
    if (self.index < self.bytes.len) {
        self.index += num;
        if (self.len > 0) {
            self.len = @max((self.len - num), 0);
        }
    }
}

test "chars iterator" {
    var chars = Chars.init("asdf");
    try testing.expect(chars.len == 4);
    try testing.expectEqual('a', chars.next().?);
    try testing.expectEqual('s', chars.next().?);
    try testing.expectEqual('d', chars.next().?);
    try testing.expectEqual('f', chars.next().?);
    try testing.expectEqual(null, chars.next());
}

test "chars skip ahead" {
    var chars = Chars.init("local name");
    chars.take(6);
    try testing.expectEqual(6, chars.index);
    try testing.expectEqual('n', chars.next().?);
}
