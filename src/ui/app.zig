const util = @import("util.zig");
const raylib = util.raylib;

const workspace = @import("workspace.zig");

var toggled: bool = false;
pub fn app(rec: util.Rect) void {
    rec.draw(util.theme.current_theme.background_color);
    if (raylib.IsKeyPressed(raylib.KEY_ESCAPE)) toggled = !toggled;
    workspace.workspace(rec);
    if (toggled) {
        // escape menu should be drawn here
        rec.draw(util.theme.current_theme.escape_color);
    }
}

pub fn start() void {
    raylib.SetTargetFPS(144);
    util.theme.setTheme(&util.theme.dark);
}

pub fn ui() void {
    const width: f32 = @floatFromInt(raylib.GetScreenWidth());
    const height: f32 = @floatFromInt(raylib.GetScreenHeight());
    const rec = util.Rect{ .min_x = 0, .min_y = 0, .max_x = width, .max_y = height };
    app(rec);
}

pub fn stop() void {}
