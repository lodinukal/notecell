const std = @import("std");
const raylib = @import("raylib.zig");

const app = @import("ui/app.zig");

pub fn main() !void {
    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE);
    raylib.InitWindow(1280, 720, "notecell!");
    defer raylib.CloseWindow();

    raylib.SetExitKey(0);

    app.start();
    defer app.stop();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);

        app.ui();

        raylib.EndDrawing();
    }
}
