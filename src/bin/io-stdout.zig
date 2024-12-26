const std = @import("std");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    try stdout_file.writeAll("hello");
}
