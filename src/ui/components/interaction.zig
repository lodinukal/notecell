const util = @import("../util.zig");
const raylib = util.raylib;

pub const InteractionState = enum {
    none,
    pressed,
    held,
    released,
    hover,
};

pub fn interactor(rec: util.Rect) InteractionState {
    if (rec.mouseWithin()) {
        if (mouseState(.pressed, null)) {
            return InteractionState.pressed;
        } else if (mouseState(.held, null)) {
            return InteractionState.held;
        } else if (mouseState(.released, null)) {
            return InteractionState.released;
        } else {
            return InteractionState.hover;
        }
    } else {
        return InteractionState.none;
    }
}

pub const ButtonLevel = enum {
    primary,
    secondary,
};

pub inline fn colorFromStates(level: ButtonLevel, state: InteractionState) raylib.Color {
    return switch (level) {
        .primary => switch (state) {
            .hover => util.theme.current_theme.primary_button_hover_color,
            .pressed, .held => util.theme.current_theme.primary_button_pressed_color,
            else => util.theme.current_theme.primary_button_color,
        },
        .secondary => switch (state) {
            .hover => util.theme.current_theme.secondary_button_hover_color,
            .pressed, .held => util.theme.current_theme.secondary_button_pressed_color,
            else => util.theme.current_theme.secondary_button_color,
        },
    };
}

pub inline fn outlineColorFromLevel(level: ButtonLevel) raylib.Color {
    return switch (level) {
        .primary => util.theme.current_theme.primary_button_outline_color,
        .secondary => util.theme.current_theme.secondary_button_outline_color,
    };
}

pub fn button(rec: util.Rect, level: ButtonLevel) InteractionState {
    const state = interactor(rec);
    rec.draw(colorFromStates(level, state));
    rec.drawRoundedLines(2, outlineColorFromLevel(level), .inner);

    return state;
}

var processed_mouse_this_frame: bool = false;
pub const MouseState = enum {
    pressed,
    released,
    held,
};
pub fn mouseState(state: MouseState, use: ?c_int) bool {
    if (processed_mouse_this_frame) {
        return false;
    }
    switch (state) {
        .pressed => {
            if (raylib.IsMouseButtonPressed(use orelse raylib.MOUSE_LEFT_BUTTON)) {
                processed_mouse_this_frame = true;
                return true;
            }
        },
        .released => {
            if (raylib.IsMouseButtonReleased(use orelse raylib.MOUSE_LEFT_BUTTON)) {
                processed_mouse_this_frame = true;
                return true;
            }
        },
        .held => {
            if (raylib.IsMouseButtonDown(use orelse raylib.MOUSE_LEFT_BUTTON)) {
                processed_mouse_this_frame = true;
                return true;
            }
        },
    }
    return false;
}

pub fn useMouse() void {
    processed_mouse_this_frame = true;
}

pub fn isMouseProcessed() bool {
    return processed_mouse_this_frame;
}

var processed_keyboard_this_frame: bool = false;

pub const KeyState = enum {
    pressed,
    released,
    held,
};

pub fn keyState(state: KeyState, key: c_int) bool {
    if (processed_keyboard_this_frame) {
        return false;
    }
    switch (state) {
        .pressed => {
            if (raylib.IsKeyPressed(key)) {
                processed_keyboard_this_frame = true;
                return true;
            }
        },
        .released => {
            if (raylib.IsKeyReleased(key)) {
                processed_keyboard_this_frame = true;
                return true;
            }
        },
        .held => {
            if (raylib.IsKeyDown(key)) {
                processed_keyboard_this_frame = true;
                return true;
            }
        },
    }
    return false;
}

pub fn resetInputState() void {
    processed_mouse_this_frame = false;
    processed_keyboard_this_frame = false;
}

pub const Resizer = struct {
    sides: struct {
        left: ?f32 = null,
        right: ?f32 = null,
        top: ?f32 = null,
        bottom: ?f32 = null,
    } = .{},
    prev_mouse_pos: ?raylib.Vector2 = null,
    captured_area: ?util.Area = null,

    pub inline fn usingSides(sides: struct {
        left: bool = false,
        right: bool = false,
        top: bool = false,
        bottom: bool = false,
    }) Resizer {
        return Resizer{
            .sides = .{
                .left = if (sides.left) 0 else null,
                .right = if (sides.right) 0 else null,
                .top = if (sides.top) 0 else null,
                .bottom = if (sides.bottom) 0 else null,
            },
        };
    }

    pub fn with(state: *Resizer, rec: util.Rect) bool {
        const mouse_pos = raylib.GetMousePosition();

        var edges = rec.getEdges(3, 3);

        state.sides.left = if (state.sides.left != null) 0 else null;
        state.sides.right = if (state.sides.right != null) 0 else null;
        state.sides.top = if (state.sides.top != null) 0 else null;
        state.sides.bottom = if (state.sides.bottom != null) 0 else null;

        var set_icon = false;
        inline for (.{
            .{ edges.top_left.mouseWithin(), .top_left },
            .{ edges.top_right.mouseWithin(), .top_right },
            .{ edges.bottom_left.mouseWithin(), .bottom_left },
            .{ edges.bottom_right.mouseWithin(), .bottom_right },
            .{ edges.left.mouseWithin(), .left },
            .{ edges.right.mouseWithin(), .right },
            .{ edges.top.mouseWithin(), .top },
            .{ edges.bottom.mouseWithin(), .bottom },
        }) |x| {
            if (x.@"0" or state.captured_area == x.@"1") {
                util.setMouseEdgeIcon(x.@"1");
                set_icon = true;

                if (mouseState(.pressed, null)) {
                    state.captured_area = x.@"1";
                }
            }

            if (x.@"1" == state.captured_area) {
                if (mouseState(.released, null)) {
                    state.captured_area = null;
                    state.prev_mouse_pos = null;
                } else {
                    if (state.prev_mouse_pos) |prev_mouse_pos| {
                        const delta_x = mouse_pos.x - prev_mouse_pos.x;
                        const delta_y = mouse_pos.y - prev_mouse_pos.y;
                        switch (x.@"1") {
                            .top_left => {
                                state.sides.top.? += delta_y;
                                state.sides.left.? += delta_x;
                            },
                            .top_right => {
                                state.sides.top.? += delta_y;
                                state.sides.right.? += delta_x;
                            },
                            .bottom_left => {
                                state.sides.bottom.? += delta_y;
                                state.sides.left.? += delta_x;
                            },
                            .bottom_right => {
                                state.sides.bottom.? += delta_y;
                                state.sides.right.? += delta_x;
                            },
                            .left => state.sides.left.? += delta_x,
                            .right => state.sides.right.? += delta_x,
                            .top => state.sides.top.? += delta_y,
                            .bottom => state.sides.bottom.? += delta_y,
                            else => {},
                        }
                    }
                    state.prev_mouse_pos = mouse_pos;
                }
            }
            if (set_icon) {
                useMouse();
                return true;
            }
        }
        if (!set_icon) {
            util.setMouseEdgeIcon(null);
            return false;
        }

        unreachable;
    }

    pub fn displace(state: *Resizer, side: util.Area, amount: f32) void {
        if (state.prev_mouse_pos) |*pmp| {
            switch (side) {
                .left => pmp.x -= amount,
                .right => pmp.x -= amount,
                .top => pmp.y -= amount,
                .bottom => pmp.y -= amount,
                .top_left => {
                    pmp.x += amount;
                    pmp.y += amount;
                },
                .top_right => {
                    pmp.x -= amount;
                    pmp.y += amount;
                },
                .bottom_left => {
                    pmp.x += amount;
                    pmp.y -= amount;
                },
                .bottom_right => {
                    pmp.x -= amount;
                    pmp.y -= amount;
                },
            }
        }
    }
};

pub const WindowResizer = struct {
    resizer: Resizer = Resizer.usingSides(.{
        .left = true,
        .right = true,
        .top = true,
        .bottom = true,
    }),
    rect: util.Rect,
    min_size: ?raylib.Vector2 = null,
    max_size: ?raylib.Vector2 = null,
    captured_mouse_position: ?raylib.Vector2 = null,

    pub fn with(state: *WindowResizer) bool {
        if (state.resizer.with(state.rect)) {
            var work_rect = state.rect;
            const changed_left = state.resizer.sides.left.? != 0;
            const changed_right = state.resizer.sides.right.? != 0;
            const changed_top = state.resizer.sides.top.? != 0;
            const changed_bottom = state.resizer.sides.bottom.? != 0;
            if (changed_left) {
                work_rect.min_x += state.resizer.sides.left.?;
            }
            if (changed_right) {
                work_rect.max_x += state.resizer.sides.right.?;
            }
            if (changed_top) {
                work_rect.min_y += state.resizer.sides.top.?;
            }
            if (changed_bottom) {
                work_rect.max_y += state.resizer.sides.bottom.?;
            }
            const ideal_rect = work_rect;
            if (state.min_size) |ms| {
                if (work_rect.width() < ms.x) {
                    if (changed_left) {
                        work_rect.min_x = work_rect.max_x - ms.x;
                    } else if (changed_right) {
                        work_rect.max_x = work_rect.min_x + ms.x;
                    }
                }
                if (work_rect.height() < ms.y) {
                    if (changed_top) {
                        work_rect.min_y = work_rect.max_y - ms.y;
                    } else if (changed_bottom) {
                        work_rect.max_y = work_rect.min_y + ms.y;
                    }
                }
            }
            if (state.max_size) |ms| {
                if (work_rect.width() > ms.x) {
                    if (changed_left) {
                        work_rect.min_x = work_rect.max_x - ms.x;
                    } else if (changed_right) {
                        work_rect.max_x = work_rect.min_x + ms.x;
                    }
                }
                if (work_rect.height() > ms.y) {
                    if (changed_top) {
                        work_rect.min_y = work_rect.max_y - ms.y;
                    } else if (changed_bottom) {
                        work_rect.max_y = work_rect.min_y + ms.y;
                    }
                }
            }
            state.rect = work_rect;

            if (changed_left) {
                state.resizer.displace(.left, ideal_rect.min_x - work_rect.min_x);
            }
            if (changed_right) {
                state.resizer.displace(.right, ideal_rect.max_x - work_rect.max_x);
            }
            if (changed_top) {
                state.resizer.displace(.top, ideal_rect.min_y - work_rect.min_y);
            }
            if (changed_bottom) {
                state.resizer.displace(.bottom, ideal_rect.max_y - work_rect.max_y);
            }

            return true;
        }

        if (state.rect.mouseClick()) {
            state.captured_mouse_position = raylib.GetMousePosition();
        }

        if (state.captured_mouse_position) |cmp| {
            if (state.rect.mouseRelease()) {
                state.captured_mouse_position = null;
                return false;
            } else {
                const delta = raylib.Vector2Subtract(raylib.GetMousePosition(), cmp);
                state.rect = state.rect.translate(delta.x, delta.y);
                state.captured_mouse_position = raylib.GetMousePosition();
                useMouse();
                return true;
            }
        }

        return false;
    }

    pub fn reset(state: *WindowResizer) void {
        state.captured_mouse_position = null;
    }
};
