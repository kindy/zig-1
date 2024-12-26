const std = @import("std");

pub fn main() !void {
    _ = try std.posix.write(1, "hello");
}
