const std = @import("std");

const util = @import("util.zig");
const raylib = util.raylib;

var topbar_height: f32 = 45.0;
var topbar_resizer = util.Resizer.usingSides(.{
    .bottom = true,
});

var zoom: f32 = 1.0;
var view_offset: raylib.Vector2 = .{ .x = 0.0, .y = 0.0 };

var points: [5]raylib.Vector2 = .{
    .{ .x = 1.0, .y = 1.0 },
    .{ .x = 2.0, .y = 1.0 },
    .{ .x = 2.0, .y = 2.0 },
    .{ .x = 3.0, .y = 2.0 },
    .{ .x = 4.0, .y = 1.0 },
};

pub fn workspace(rec: util.Rect) void {
    var _rec = rec;
    const topbar_rec = _rec.cutTop(topbar_height);

    // if (topbar_resizer.with(topbar_rec)) {
    //     const full_displacement = topbar_height + topbar_resizer.sides.bottom.?;
    //     topbar_height = std.math.clamp(topbar_height + topbar_resizer.sides.bottom.?, 30, 90);
    //     topbar_resizer.displace(.bottom, full_displacement - topbar_height);
    // }
    var rest_of_viewport = _rec;

    const cell_size: f32 = 100 / zoom;

    const half_x: f32 = rest_of_viewport.width() / 2;
    const half_y: f32 = rest_of_viewport.height() / 2;

    const center_x = view_offset.x;
    const center_y = view_offset.y;

    const left_bound = center_x - (half_x * zoom);
    const right_bound = center_x + (half_x * zoom);
    const top_bound = center_y - (half_y * zoom);
    const bottom_bound = center_y + (half_y * zoom);

    const left_bound_cell: isize = @intFromFloat(std.math.floor(left_bound / cell_size));
    const right_bound_cell: isize = @intFromFloat(std.math.floor(right_bound / cell_size));
    const horizontal_cells = right_bound_cell - left_bound_cell;

    const top_bound_cell: isize = @intFromFloat(std.math.floor(top_bound / cell_size));
    const bottom_bound_cell: isize = @intFromFloat(std.math.floor(bottom_bound / cell_size));
    const vertical_cells = bottom_bound_cell - top_bound_cell;

    var y: isize = top_bound_cell - 1; //right_boung_cell - 1;
    while (y <= bottom_bound_cell + 1) : (y += 1) {
        var x: isize = left_bound_cell - 1; //left_bound_cell - 1;
        while (x <= right_bound_cell + 1) : (x += 1) {
            const float_x: f32 = @floatFromInt(x);
            const float_y: f32 = @floatFromInt(y);

            var cell_rec = util.Rect{
                .min_x = (float_x * cell_size),
                .min_y = (float_y * cell_size),
                .max_x = ((float_x + 1) * cell_size),
                .max_y = ((float_y + 1) * cell_size),
            };

            cell_rec.translate(half_x, half_y)
                .translate(-view_offset.x, -view_offset.y)
                .drawLines(1, util.theme.current_theme.grid_color);
        }
    }

    // objects
    for (points) |point| {
        const within_horizontal = point.x >= @as(f32, @floatFromInt(left_bound_cell)) and point.x <= @as(f32, @floatFromInt(right_bound_cell));
        const within_vertical = point.y >= @as(f32, @floatFromInt(top_bound_cell)) and point.y <= @as(f32, @floatFromInt(bottom_bound_cell));
        if (!within_horizontal or !within_vertical) {
            continue;
        }

        const percent_x: f32 = (point.x - @as(f32, @floatFromInt(left_bound_cell))) / @as(f32, @floatFromInt(horizontal_cells));
        const percent_y: f32 = (point.y - @as(f32, @floatFromInt(top_bound_cell))) / @as(f32, @floatFromInt(vertical_cells));

        const point_x: f32 = std.math.lerp(@as(f32, @floatFromInt(left_bound_cell)), @as(f32, @floatFromInt(right_bound_cell)), percent_x) * cell_size;
        const point_y: f32 = std.math.lerp(@as(f32, @floatFromInt(top_bound_cell)), @as(f32, @floatFromInt(bottom_bound_cell)), percent_y) * cell_size;

        raylib.DrawCircle(
            @intFromFloat(point_x - view_offset.x + half_x),
            @intFromFloat(point_y - view_offset.y + half_y),
            5,
            raylib.RED,
        );
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

    if (raylib.IsKeyDown(raylib.KEY_W)) {
        view_offset.y -= 1.0;
    }
    if (raylib.IsKeyDown(raylib.KEY_S)) {
        view_offset.y += 1.0;
    }
    if (raylib.IsKeyDown(raylib.KEY_A)) {
        view_offset.x -= 1.0;
    }
    if (raylib.IsKeyDown(raylib.KEY_D)) {
        view_offset.x += 1.0;
    }
    const dir = raylib.GetMouseWheelMove();
    if (dir != 0) {
        zoom = std.math.clamp(zoom + (dir * 0.1), 0.1, 3.0);
    }
}
