const std = @import("std");

const app = @import("../app.zig");

const Project = @import("../../store/store.zig").Project;
const Scene = @import("../../store/store.zig").Scene;
const Card = @import("../../store/store.zig").Card;

const util = @import("../util.zig");
const raylib = util.raylib;

const textui = @import("text.zig");
const interaction = @import("interaction.zig");

var captured_mouse_pos: ?raylib.Vector2 = null;
var captured_card: ?*Card = null;
const round_to = 20.0;

var processed_card: bool = false;
pub fn card(c: *Card, cam: raylib.Camera2D) !void {
    const card_color = blk: {
        if (c.color) |col|
            break :blk raylib.Color{
                .r = col[0],
                .g = col[1],
                .b = col[2],
                .a = col[3],
            };
        break :blk util.theme.current_theme.card_color;
    };

    const rec = util.Rect{
        .min_x = c.rect.min_x,
        .min_y = c.rect.min_y,
        .max_x = c.rect.max_x,
        .max_y = c.rect.max_y,
    };

    const mouse_pos = raylib.GetMousePosition();
    const mouse_world_pos = raylib.GetScreenToWorld2D(mouse_pos, cam);
    var within = rec.mouseWithinCamera(cam);
    if (within) {
        if (processed_card) within = false;
        processed_card = true;

        if (interaction.mouseState(.pressed, null)) {
            captured_mouse_pos = mouse_world_pos;
            captured_card = c;
        }
    }
    if (captured_card == c) {
        rec.drawLines(3.0 / cam.zoom, util.theme.current_theme.card_outline_color, .outer);
        if (captured_mouse_pos) |cmp| {
            if (interaction.mouseState(.released, null)) {
                captured_mouse_pos = null;
                // round c.rect
                const old_min_x = c.rect.min_x;
                const old_min_y = c.rect.min_y;
                c.rect.min_x = std.math.round(c.rect.min_x / round_to) * round_to;
                c.rect.min_y = std.math.round(c.rect.min_y / round_to) * round_to;

                const diff_x = c.rect.min_x - old_min_x;
                const diff_y = c.rect.min_y - old_min_y;

                c.rect.max_x += diff_x;
                c.rect.max_y += diff_y;
            } else {
                const delta = raylib.Vector2Subtract(mouse_world_pos, cmp);
                c.rect.min_x += delta.x;
                c.rect.min_y += delta.y;
                c.rect.max_x += delta.x;
                c.rect.max_y += delta.y;
                captured_mouse_pos = mouse_world_pos;
            }
        }
    }

    rec.draw(card_color);
    rec.extendAll(-10).drawText(
        util.theme.current_theme.regular_font.loaded.?,
        c.name,
        0,
        if (within) util.theme.current_theme.main_text_color else util.theme.current_theme.secondary_text_color,
        .center,
    );

    switch (c.inner) {
        .board => |board| {
            _ = board;
        },
        .column => |column| {
            _ = column;
        },
        .note => |note| {
            _ = note;
        },
    }
}

pub fn reset() void {
    processed_card = false;
}

pub fn deselect() void {
    captured_card = null;
}
