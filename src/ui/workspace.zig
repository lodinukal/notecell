const std = @import("std");

const util = @import("util.zig");
const raylib = util.raylib;

var topbar_height: f32 = 45.0;
var topbar_resizer = util.Resizer.usingSides(.{
    .bottom = true,
});

var cam: raylib.Camera2D = .{
    .zoom = 1,
    .offset = .{ .x = 0, .y = 0 },
    .rotation = 0,
};
var prev_mouse_pos: ?raylib.Vector2 = null;
var captured_mouse: bool = false;

var points: [6]raylib.Vector2 = .{
    .{ .x = 0.0, .y = 0.0 },
    .{ .x = 1.0, .y = 1.0 },
    .{ .x = 2.0, .y = 1.0 },
    .{ .x = 2.0, .y = 2.0 },
    .{ .x = 3.0, .y = 2.0 },
    .{ .x = 4.0, .y = 1.0 },
};

pub fn workspace(rec: util.Rect, block_inputs: bool) void {
    var rest_of_viewport = rec;
    const topbar_rec = rest_of_viewport.cutTop(topbar_height);

    const view_x: f32 = rest_of_viewport.width();
    const view_y: f32 = rest_of_viewport.height();
    const view_half_x: f32 = view_x / 2;
    const view_half_y: f32 = view_y / 2;
    cam.offset.x = view_half_x;
    cam.offset.y = view_half_y;

    {
        raylib.BeginMode2D(cam);
        defer raylib.EndMode2D();

        const grid_x = std.math.ceil((cam.target.x) / 100) * 100;
        const grid_y = std.math.ceil((cam.target.y) / 100) * 100;

        const rounded_zoom = std.math.ceil(1 / cam.zoom / 100) * 100;

        const left_bound = std.math.ceil((grid_x - view_half_x * rounded_zoom) / 100) * 100;
        const right_bound = std.math.ceil((grid_x + view_half_x * rounded_zoom) / 100) * 100;
        const top_bound = std.math.ceil((grid_y - view_half_y * rounded_zoom) / 100) * 100;
        const bottom_bound = std.math.ceil((grid_y + view_half_y * rounded_zoom) / 100) * 100;

        var x = left_bound;
        while (x <= right_bound) : (x += 100) {
            raylib.DrawLineEx(
                .{ .x = x, .y = top_bound },
                .{ .x = x, .y = bottom_bound },
                3 / cam.zoom,
                util.theme.current_theme.grid_color,
            );
        }

        var y = top_bound;
        while (y <= bottom_bound) : (y += 100) {
            raylib.DrawLineEx(
                .{ .x = left_bound, .y = y },
                .{ .x = right_bound, .y = y },
                3 / cam.zoom,
                util.theme.current_theme.grid_color,
            );
        }

        // objects
        for (points, 0..) |point, idx| {
            const converted_point = raylib.Vector2Multiply(point, .{
                .x = 50,
                .y = 50,
            });
            const within_horizontal = converted_point.x >= left_bound and converted_point.x <= right_bound;
            const within_vertical = converted_point.y >= top_bound and converted_point.y <= bottom_bound;
            if (!within_horizontal or !within_vertical) {
                continue;
            }

            raylib.DrawCircle(
                @intFromFloat(converted_point.x),
                @intFromFloat(converted_point.y),
                5,
                if (idx == 0) raylib.RED else raylib.BLUE,
            );
        }
    }

    // draw topbar over
    {
        topbar_rec.draw(util.theme.current_theme.foreground_color);
        topbar_rec.drawLines(2, util.theme.current_theme.main_outline_color, .outer);

        var text_rect = topbar_rec.extendAll(-10);
        text_rect.drawText(
            util.theme.current_theme.bold_font.loaded.?,
            "WORKSPACE",
            0.0,
            util.theme.current_theme.main_text_color,
        );
    }

    // position element
    {
        var text_buffer: [256]u8 = .{0} ** 256;
        var fba = std.heap.FixedBufferAllocator.init(&text_buffer);
        const text_allocator = fba.allocator();

        var markers = rest_of_viewport.extendAll(-10);
        var marker = markers.getRight(120).getBottom(35);
        const text = std.fmt.allocPrint(text_allocator, "({}, {})", .{
            @as(isize, @intFromFloat(cam.target.x)),
            @as(isize, @intFromFloat(cam.target.y)),
        }) catch "?";

        var text_rec = marker.extendAll(-8);
        const text_size = raylib.MeasureTextEx(util.theme.current_theme.regular_font.loaded.?, text.ptr, text_rec.height(), 0.0);

        marker = marker.getRight(text_size.x + 16);
        marker.draw(util.theme.current_theme.foreground_color);
        marker.drawRoundedLines(2, util.theme.current_theme.secondary_outline_color, .inner);

        marker.extendAll(-8).drawText(
            util.theme.current_theme.regular_font.loaded.?,
            text,
            0.0,
            util.theme.current_theme.secondary_text_color,
        );
    }

    if (!block_inputs) {
        if (prev_mouse_pos) |pmp| {
            const this_pos = raylib.GetMousePosition();
            const delta = raylib.Vector2Subtract(pmp, this_pos);
            if (raylib.IsMouseButtonPressed(raylib.MOUSE_BUTTON_LEFT) and rest_of_viewport.mouseWithin()) {
                captured_mouse = true;
            }
            if (captured_mouse) {
                cam.target = raylib.GetScreenToWorld2D(raylib.Vector2Add(cam.offset, delta), cam);
                if (raylib.IsMouseButtonReleased(raylib.MOUSE_BUTTON_LEFT)) {
                    captured_mouse = false;
                }
            }
        }
        prev_mouse_pos = raylib.GetMousePosition();

        const dir = raylib.GetMouseWheelMove();
        if (dir != 0) {
            cam.zoom = std.math.clamp(cam.zoom + (dir * 0.1), 0.1, 3.0);
        }
    } else {
        captured_mouse = false;
    }
}
