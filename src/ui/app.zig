const util = @import("util.zig");
const raylib = util.raylib;

const Project = @import("../store/store.zig").Project;

const workspace = @import("components/workspace.zig");
const interaction = @import("components/interaction.zig");

var toggled: bool = false;
pub fn app(rec: util.Rect) void {
    rec.draw(util.theme.current_theme.background_color);
    if (raylib.IsKeyPressed(raylib.KEY_ESCAPE)) toggled = !toggled;
    if (toggled) interaction.useMouse();
    workspace.workspace(rec, toggled);
    if (toggled) {
        // escape menu should be drawn here
        rec.draw(util.theme.current_theme.escape_color);
    }
}

pub var using_project: ?*Project = null;
pub fn start(project: ?*Project) void {
    using_project = project;
    raylib.SetTargetFPS(144);
    util.theme.setTheme(&util.theme.dark);
}

pub fn ui() void {
    const width: f32 = @floatFromInt(raylib.GetScreenWidth());
    const height: f32 = @floatFromInt(raylib.GetScreenHeight());
    const rec = util.Rect{ .min_x = 0, .min_y = 0, .max_x = width, .max_y = height };
    app(rec);
    interaction.resetInputState();
}

pub fn stop() void {}
