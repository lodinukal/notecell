const std = @import("std");
const raylib = @import("raylib.zig");

const Project = @import("store/store.zig").Project;
const app = @import("ui/app.zig");

pub const std_options = struct {
    pub const log_scope_levels = &.{
        .{ .scope = .tokenizer, .level = .warn },
        // .{ .scope = .parse, .level = .warn },
    };
};

fn in_main(allocator: std.mem.Allocator) !void {
    const path = "../../example";
    const normal_dir = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(normal_dir);

    var base_dir = try std.fs.openDirAbsolute(normal_dir, .{});
    defer base_dir.close();

    try base_dir.makePath(path);

    var dir = try base_dir.openDir(path, .{});
    defer dir.close();

    var proj = try Project.createWithServeDir(allocator, dir, null);
    defer proj.destroy();

    proj.readProjectOrInit() catch |err| {
        std.log.err("Failed to init project: {}\n", .{err});
    };

    raylib.SetTraceLogLevel(raylib.LOG_ERROR);
    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE);
    raylib.InitWindow(1280, 720, "notecell");
    defer raylib.CloseWindow();

    raylib.SetExitKey(0);

    app.start(proj);
    defer app.stop();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);

        app.ui();

        raylib.EndDrawing();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try in_main(allocator);
}
