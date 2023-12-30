const std = @import("std");

const app = @import("../app.zig");

const Project = @import("../../store/store.zig").Project;
const Scene = @import("../../store/store.zig").Scene;

const util = @import("../util.zig");
const raylib = util.raylib;

const textui = @import("text.zig");
const interaction = @import("interaction.zig");
const card = @import("card.zig");

var topbar_height: f32 = 45.0;
var topbar_resizer = interaction.Resizer.usingSides(.{
    .bottom = true,
});

var cam: raylib.Camera2D = .{
    .zoom = 1,
    .offset = .{ .x = 0, .y = 0 },
    .rotation = 0,
};
var prev_mouse_pos: ?raylib.Vector2 = null;
var captured_mouse: bool = false;

pub fn workspace(rec: util.Rect, block_inputs: bool) void {
    var rest_of_viewport = rec;
    const topbar_rec = rest_of_viewport.cutTop(topbar_height);

    const view_x: f32 = rest_of_viewport.width();
    const view_y: f32 = rest_of_viewport.height();
    const view_half_x: f32 = view_x / 2;
    const view_half_y: f32 = view_y / 2;
    cam.offset.x = view_half_x;
    cam.offset.y = view_half_y;

    var current_scene: ?*Scene = if (app.using_project) |proj|
        proj.current_loaded_scene
    else
        null;
    _ = &current_scene;

    if (current_scene) |scene| {
        raylib.BeginMode2D(cam);
        defer raylib.EndMode2D();

        const cell_gap: f32 = blk: {
            // make keep at 20 by default
            // but as cam.zoom increases, decrease the cell gap
            if (cam.zoom >= 1.5) break :blk 10;
            break :blk 20;
        };

        const grid_x = std.math.ceil((cam.target.x) / cell_gap) * cell_gap;
        const grid_y = std.math.ceil((cam.target.y) / cell_gap) * cell_gap;

        const rounded_zoom = std.math.ceil(1 / cam.zoom / cell_gap) * cell_gap;

        const left_bound = std.math.ceil((grid_x - view_half_x * rounded_zoom) / cell_gap) * cell_gap;
        const right_bound = std.math.ceil((grid_x + view_half_x * rounded_zoom) / cell_gap) * cell_gap;
        const top_bound = std.math.ceil((grid_y - view_half_y * rounded_zoom) / cell_gap) * cell_gap;
        const bottom_bound = std.math.ceil((grid_y + view_half_y * rounded_zoom) / cell_gap) * cell_gap;

        var x = left_bound;
        while (x <= right_bound) : (x += cell_gap) {
            raylib.DrawLineEx(
                .{ .x = x, .y = top_bound },
                .{ .x = x, .y = bottom_bound },
                3 / cam.zoom,
                util.theme.current_theme.grid_color,
            );
        }

        var y = top_bound;
        while (y <= bottom_bound) : (y += cell_gap) {
            raylib.DrawLineEx(
                .{ .x = left_bound, .y = y },
                .{ .x = right_bound, .y = y },
                3 / cam.zoom,
                util.theme.current_theme.grid_color,
            );
        }

        card.reset();
        for (scene.cards.items) |*c| {
            card.card(c, cam) catch {};
        }
    } else {
        rest_of_viewport.centered(120, 30).drawText(
            util.theme.current_theme.bold_font.loaded.?,
            "No project open ;-;",
            0.0,
            util.theme.current_theme.main_text_color,
            .center,
        );
    }

    // draw topbar over
    {
        topbar_rec.draw(util.theme.current_theme.foreground_color);
        topbar_rec.drawLines(2, util.theme.current_theme.main_outline_color, .outer);

        // if (topbar_resizer.with(topbar_rec)) {
        //     const unclamped_height = topbar_height + topbar_resizer.sides.bottom.?;
        //     topbar_height = std.math.clamp(unclamped_height, 45, 60);
        //     topbar_resizer.displace(.bottom, unclamped_height - topbar_height);
        // }

        var text_buffer: [256]u8 = .{0} ** 256;
        var fba = std.heap.FixedBufferAllocator.init(&text_buffer);
        const text_allocator = fba.allocator();

        var text_rect = topbar_rec.extendAll(-10);

        const text = if (current_scene) |scene|
            std.fmt.allocPrint(text_allocator, "{s}", .{scene.name}) catch "?"
        else
            std.fmt.allocPrint(text_allocator, "No scene open", .{}) catch "?";
        text_rect.drawText(
            util.theme.current_theme.bold_font.loaded.?,
            text,
            0.0,
            util.theme.current_theme.main_text_color,
            .left,
        );

        const button_rec = topbar_rec.extendAll(-8).getRight(50);
        if (interaction.button(button_rec, .primary) == .pressed) {}
    }

    // position element
    if (current_scene) |scene| {
        _ = scene;

        var text_buffer: [256]u8 = .{0} ** 256;
        var fba = std.heap.FixedBufferAllocator.init(&text_buffer);
        const text_allocator = fba.allocator();

        var markers = rest_of_viewport.extendAll(-10);
        const marker = markers.getRight(120).getBottom(35);
        const text = std.fmt.allocPrint(text_allocator, "({}, {})", .{
            @as(isize, @intFromFloat(cam.target.x)),
            @as(isize, @intFromFloat(cam.target.y)),
        }) catch "?";

        if (textui.textButtonExpanding(
            marker,
            text,
            util.theme.current_theme.regular_font.loaded.?,
            .right,
            util.theme.current_theme.secondary_text_color,
            .primary,
        ) == .pressed) {
            std.log.warn("pressed", .{});
        }
    }

    if (!block_inputs and !interaction.isMouseProcessed() and current_scene != null) {
        if (prev_mouse_pos) |pmp| {
            const this_pos = raylib.GetMousePosition();
            const delta = raylib.Vector2Subtract(pmp, this_pos);
            if (rest_of_viewport.mouseWithin() and interaction.mouseState(.pressed, raylib.MOUSE_BUTTON_MIDDLE)) {
                captured_mouse = true;
            }
            if (captured_mouse) {
                cam.target = raylib.GetScreenToWorld2D(raylib.Vector2Add(cam.offset, delta), cam);
                if (interaction.mouseState(.released, raylib.MOUSE_BUTTON_MIDDLE)) {
                    captured_mouse = false;
                }
            }
        }
        prev_mouse_pos = raylib.GetMousePosition();

        const dir = raylib.GetMouseWheelMove();
        if (dir != 0) {
            cam.zoom = std.math.clamp(cam.zoom + (dir * 0.1), 0.5, 2.0);
        }

        const mouse_pos = raylib.GetMousePosition();
        const world_pos = raylib.GetScreenToWorld2D(mouse_pos, cam);
        _ = world_pos; // autofix

        if (rest_of_viewport.mouseClick()) {
            card.deselect();
        }

        // if (rest_of_viewport.mouseClick()) {
        //     current_scene.?.cards.append(.{
        //         .name = "a card",
        //         .rect = .{
        //             .min_x = world_pos.x,
        //             .min_y = world_pos.y,
        //             .max_x = world_pos.x + 200,
        //             .max_y = world_pos.y + 50,
        //         },
        //         .inner = .{
        //             .note = .{
        //                 .allocator = current_scene.?.allocator,
        //                 .content = current_scene.?.allocator.dupeZ(u8, "hiii!") catch unreachable,
        //             },
        //         },
        //     }) catch {};
        // }
    } else {
        captured_mouse = false;
    }
}
