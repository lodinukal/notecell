const std = @import("std");

pub const raylib = @import("../raylib.zig");

pub const theme = @import("theme.zig");

// rectcut implementation
pub const Rect = struct {
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,

    pub inline fn toRaylib(self: Rect) raylib.Rectangle {
        return raylib.Rectangle{
            .x = self.min_x,
            .y = self.min_y,
            .width = self.max_x - self.min_x,
            .height = self.max_y - self.min_y,
        };
    }

    pub inline fn fromRaylib(rec: raylib.Rectangle) Rect {
        return Rect{
            .min_x = rec.x,
            .min_y = rec.y,
            .max_x = rec.x + rec.width,
            .max_y = rec.y + rec.height,
        };
    }

    pub inline fn cutLeft(self: *Rect, amount: f32) Rect {
        const min_x: f32 = self.min_x;
        self.min_x = @min(self.max_x, self.min_x + amount);
        return Rect{
            .min_x = min_x,
            .min_y = self.min_y,
            .max_x = self.min_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn cutRight(self: *Rect, amount: f32) Rect {
        const original_x = self.max_x;
        self.max_x = @max(self.min_x, self.max_x - amount);
        return Rect{
            .min_x = self.max_x,
            .min_y = self.min_y,
            .max_x = original_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn cutTop(self: *Rect, amount: f32) Rect {
        const original_y = self.min_y;
        self.min_y = @min(self.max_y, self.min_y + amount);
        return Rect{
            .min_x = self.min_x,
            .min_y = original_y,
            .max_x = self.max_x,
            .max_y = self.min_y,
        };
    }

    pub inline fn cutBottom(self: *Rect, amount: f32) Rect {
        const original_y = self.max_y;
        self.max_y = @max(self.min_y, self.max_y - amount);
        return Rect{
            .min_x = self.min_x,
            .min_y = self.max_y,
            .max_x = self.max_x,
            .max_y = original_y,
        };
    }

    pub inline fn cut(self: *Rect, side: Side, amount: f32) Rect {
        switch (side) {
            .left => return self.cutLeft(amount),
            .right => return self.cutRight(amount),
            .top => return self.cutTop(amount),
            .bottom => return self.cutBottom(amount),
        }
    }

    pub inline fn getLeft(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = @max(self.min_x, self.max_x + amount),
            .min_y = self.min_y,
            .max_x = self.max_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn getRight(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .max_x = @min(self.max_x, self.min_x - amount),
            .max_y = self.max_y,
        };
    }

    pub inline fn getTop(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .max_x = self.max_x,
            .max_y = @min(self.max_y, self.min_y + amount),
        };
    }

    pub inline fn getBottom(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = @max(self.min_y, self.max_y - amount),
            .max_x = self.max_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn get(self: Rect, side: Side, amount: f32) Rect {
        switch (side) {
            .left => return self.getLeft(amount),
            .right => return self.getRight(amount),
            .top => return self.getTop(amount),
            .bottom => return self.getBottom(amount),
        }
    }

    pub inline fn extendLeft(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x - amount,
            .min_y = self.min_y,
            .max_x = self.max_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn extendRight(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .max_x = self.max_x + amount,
            .max_y = self.max_y,
        };
    }

    pub inline fn extendTop(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y - amount,
            .max_x = self.max_x,
            .max_y = self.max_y,
        };
    }

    pub inline fn extendBottom(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .max_x = self.max_x,
            .max_y = self.max_y + amount,
        };
    }

    pub inline fn extend(self: Rect, side: Side, amount: f32) Rect {
        switch (side) {
            .left => return self.extendLeft(amount),
            .right => return self.extendRight(amount),
            .top => return self.extendTop(amount),
            .bottom => return self.extendBottom(amount),
        }
    }

    pub inline fn extendAll(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x - amount,
            .min_y = self.min_y - amount,
            .max_x = self.max_x + amount,
            .max_y = self.max_y + amount,
        };
    }

    pub inline fn draw(self: Rect, color: raylib.Color) void {
        raylib.DrawRectangleRec(self.toRaylib(), color);
    }

    pub inline fn drawLines(self: Rect, thickness: f32, color: raylib.Color) void {
        raylib.DrawRectangleLinesEx(self.toRaylib(), thickness, color);
    }

    pub fn mouseWithin(self: Rect) bool {
        const mouse_pos = raylib.GetMousePosition();
        return mouse_pos.x >= self.min_x and mouse_pos.x <= self.max_x and mouse_pos.y >= self.min_y and mouse_pos.y <= self.max_y;
    }

    pub fn mouseClick(self: Rect) bool {
        return self.mouseWithin() and raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON);
    }

    pub fn mouseRelease(self: Rect) bool {
        return self.mouseWithin() and raylib.IsMouseButtonReleased(raylib.MOUSE_LEFT_BUTTON);
    }

    pub fn mouseHold(self: Rect) bool {
        return self.mouseWithin() and raylib.IsMouseButtonDown(raylib.MOUSE_LEFT_BUTTON);
    }

    pub const Edges = struct {
        left: Rect,
        right: Rect,
        top: Rect,
        bottom: Rect,
    };

    pub fn getEdges(self: Rect, amount: f32, expand: f32) Edges {
        return Edges{
            .left = self.getLeft(amount).extendLeft(expand),
            .right = self.getRight(amount).extendRight(expand),
            .top = self.getTop(amount).extendTop(expand),
            .bottom = self.getBottom(amount).extendBottom(expand),
        };
    }

    pub inline fn width(self: Rect) f32 {
        return self.max_x - self.min_x;
    }

    pub inline fn height(self: Rect) f32 {
        return self.max_y - self.min_y;
    }
};

pub const Side = enum {
    left,
    right,
    top,
    bottom,
};

pub fn setMouseEdgeIcon(side: ?Side) void {
    if (side) |s| {
        switch (s) {
            .left => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_EW),
            .right => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_EW),
            .top => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NS),
            .bottom => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NS),
        }
    } else {
        raylib.SetMouseCursor(raylib.MOUSE_CURSOR_DEFAULT);
    }
}

pub const Resizer = struct {
    sides: struct {
        left: ?f32 = null,
        right: ?f32 = null,
        top: ?f32 = null,
        bottom: ?f32 = null,
    } = .{},
    prev_mouse_pos: ?raylib.Vector2 = null,
    captured_edge: ?Side = null,

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

    pub fn with(state: *Resizer, rec: Rect) bool {
        const mouse_pos = raylib.GetMousePosition();

        var edges = rec.getEdges(3, 3);

        state.sides.left = if (state.sides.left != null) 0 else null;
        state.sides.right = if (state.sides.right != null) 0 else null;
        state.sides.top = if (state.sides.top != null) 0 else null;
        state.sides.bottom = if (state.sides.bottom != null) 0 else null;

        var set_icon = false;
        inline for (.{
            .{ edges.left.mouseWithin(), .left },
            .{ edges.right.mouseWithin(), .right },
            .{ edges.top.mouseWithin(), .top },
            .{ edges.bottom.mouseWithin(), .bottom },
        }) |x| {
            if (x.@"0" or state.captured_edge == x.@"1") {
                setMouseEdgeIcon(x.@"1");
                set_icon = true;

                if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
                    state.captured_edge = x.@"1";
                }
            }

            if (x.@"1" == state.captured_edge) {
                if (raylib.IsMouseButtonReleased(raylib.MOUSE_LEFT_BUTTON)) {
                    state.captured_edge = null;
                    state.prev_mouse_pos = null;
                } else {
                    if (state.prev_mouse_pos) |prev_mouse_pos| {
                        const delta_x = mouse_pos.x - prev_mouse_pos.x;
                        const delta_y = mouse_pos.y - prev_mouse_pos.y;
                        switch (x.@"1") {
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
            if (set_icon) return true;
        }
        if (!set_icon) {
            setMouseEdgeIcon(null);
            return false;
        }

        // if ((edges.bottom.mouseWithin() or state.captured_edge == .bottom) and state.sides.bottom != null) {
        //     setMouseEdgeIcon(.bottom);
        //     if (!edges.bottom.mouseHold()) return true;
        //     std.debug.print("bottom hold\n", .{});
        //     if (state.prev_mouse_pos) |prev_mouse_pos| {
        //         const delta = mouse_pos.y - prev_mouse_pos.y;
        //         state.sides.bottom.? += delta;
        //     }
        //     return true;
        // }

        // if ((edges.top.mouseWithin() or state.captured_edge == .top) and state.sides.top != null) {
        //     setMouseEdgeIcon(.top);
        //     if (!edges.top.mouseHold()) return true;
        //     if (state.prev_mouse_pos) |prev_mouse_pos| {
        //         const delta = mouse_pos.y - prev_mouse_pos.y;
        //         state.sides.top.? += delta;
        //     }
        //     return true;
        // }

        // if ((edges.left.mouseWithin() or state.captured_edge == .left) and state.sides.left != null) {
        //     setMouseEdgeIcon(.left);
        //     if (!edges.left.mouseHold()) return true;
        //     if (state.prev_mouse_pos) |prev_mouse_pos| {
        //         const delta = mouse_pos.x - prev_mouse_pos.x;
        //         state.sides.left.? += delta;
        //     }
        //     return true;
        // }

        // if ((edges.right.mouseWithin() or state.captured_edge == .right) and state.sides.right != null) {
        //     setMouseEdgeIcon(.right);
        //     if (!edges.right.mouseHold()) return true;
        //     if (state.prev_mouse_pos) |prev_mouse_pos| {
        //         const delta = mouse_pos.x - prev_mouse_pos.x;
        //         state.sides.right.? += delta;
        //     }
        //     return true;
        // }

        unreachable;
    }

    pub fn displace(state: *Resizer, side: Side, amount: f32) void {
        if (state.prev_mouse_pos) |*pmp| {
            switch (side) {
                .left => pmp.x += amount,
                .right => pmp.x -= amount,
                .top => pmp.y += amount,
                .bottom => pmp.y -= amount,
            }
        }
    }
};
