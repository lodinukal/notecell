const std = @import("std");

const util = @import("util.zig");
const raylib = util.raylib;

var topbar_height: f32 = 45.0;
var topbar_resizer = util.Resizer.usingSides(.{
    .bottom = true,
});
pub fn workspace(rec: util.Rect) void {
    var _rec = rec;
    const topbar_rec = _rec.cutTop(topbar_height);

    // if (topbar_resizer.with(topbar_rec)) {
    //     const full_displacement = topbar_height + topbar_resizer.sides.bottom.?;
    //     topbar_height = std.math.clamp(topbar_height + topbar_resizer.sides.bottom.?, 30, 90);
    //     topbar_resizer.displace(.bottom, full_displacement - topbar_height);
    // }
    var rest_of_viewport = _rec;

    const cell_size = 100;

    const x_cell_count: usize = @intFromFloat(std.math.floor(rest_of_viewport.width() / cell_size));
    const y_cell_count: usize = @intFromFloat(std.math.floor(rest_of_viewport.height() / cell_size));

    const x_space_left = rest_of_viewport.width() - @as(f32, @floatFromInt(x_cell_count * cell_size));
    const y_space_left = rest_of_viewport.height() - @as(f32, @floatFromInt(y_cell_count * cell_size));

    const offset_x = x_space_left / 2;
    const offset_y = y_space_left / 2;

    var start_x: usize = @intFromFloat(rest_of_viewport.min_x);
    var start_y: usize = @intFromFloat(rest_of_viewport.min_y);

    start_x += @intFromFloat(offset_x);
    start_y += @intFromFloat(offset_y);

    for (0..y_cell_count + 2) |y| {
        for (0..x_cell_count + 2) |x| {
            var cell_rec = util.Rect{
                .min_x = @floatFromInt(start_x + (x * cell_size)),
                .min_y = @floatFromInt(start_y + (y * cell_size)),
                .max_x = @floatFromInt(start_x + ((x + 1) * cell_size)),
                .max_y = @floatFromInt(start_y + ((y + 1) * cell_size)),
            };
            cell_rec.min_x -= cell_size;
            cell_rec.min_y -= cell_size;
            cell_rec.max_x -= cell_size;
            cell_rec.max_y -= cell_size;
            cell_rec.drawLines(1, util.theme.current_theme.grid_color);
        }
    }

    // draw topbar over
    topbar_rec.draw(util.theme.current_theme.foreground_color);

    var text_rect = topbar_rec.extendAll(-10);

    raylib.DrawTextEx(
        util.theme.current_theme.bold_font.loaded.?,
        "WORKSPACE",
        .{
            .x = text_rect.min_x,
            .y = text_rect.min_y,
        },
        text_rect.height(),
        0.0,
        util.theme.current_theme.main_text_color,
    );
}
