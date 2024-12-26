const std = @import("std");

pub const buildx = struct {
    b: *std.Build,
    name: []const u8,
    t: ?std.Build.ResolvedTarget,
    o: ?std.builtin.OptimizeMode,

    pub fn init(b: *std.Build, name: []const u8) buildx {
        const o: buildx = .{
            .b = b,
            .name = name,
            .t = b.standardTargetOptions(.{}),
            .o = b.standardOptimizeOption(.{}),
        };
        return o;
    }

    pub fn bin(bx: *buildx) void {
        const b = bx.b;
        const name = bx.name;

        if (std.posix.fstatat(b.build_root.handle.fd, "src/main.zig", 0)) |_| {
            bx._bin(b, b.path("src/main.zig"), name, true);
        } else |_| {}

        if (std.fs.openDirAbsolute(b.pathFromRoot("src/bin"), .{ .iterate = true })) |*binDir| {
            // defer binDir.close();
            var iter = binDir.iterate();
            while (true) {
                if (iter.next() catch {
                    break;
                }) |item| {
                    if (item.kind == .file and std.mem.endsWith(u8, item.name, ".zig")) {
                        // std.log.info("src/bin/{s}", .{item.name});
                        const bin_name = item.name[0 .. item.name.len - 4];
                        bx._bin(b, b.path(bx._fmt("src/bin/{s}", .{item.name})), bin_name, false);
                    }
                } else {
                    break;
                }
            }
        } else |_| {}
    }

    pub fn lib(bx: *buildx) void {
        const b = bx.b;
        const name = bx.name;

        if (std.posix.fstatat(b.build_root.handle.fd, "src/lib.zig", 0)) |_| {
            const lib_ = b.addSharedLibrary(.{
                .name = name,
                .root_source_file = b.path("src/lib.zig"),
                .target = bx.t.?,
                .optimize = bx.o.?,
                // .strip = true,
            });
            b.installArtifact(lib_);
        } else |_| {}
    }

    fn _fmt(bx: *buildx, comptime fmt: []const u8, args: anytype) []u8 {
        return std.fmt.allocPrint(bx.b.allocator, fmt, args) catch @panic("OOM");
    }

    fn _bin(bx: *buildx, b: *std.Build, src: std.Build.LazyPath, name: []const u8, is_main: bool) void {
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = src,
            .target = bx.t.?,
            .optimize = bx.o.?,
            // .strip = true,
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        var run_name: []const u8 = "run";
        if (!is_main) {
            run_name = bx._fmt("run-{s}", .{name});
        }
        const run_step = b.step(run_name, bx._fmt("run {s}", .{name}));
        run_step.dependOn(&run_cmd.step);
    }
};
