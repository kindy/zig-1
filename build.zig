const std = @import("std");

pub fn build(b: *std.Build) void {
    var bx = @import("buildx.zig").buildx.init(b, "zig-1");

    bx.bin();
    bx.lib();
}
