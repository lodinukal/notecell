const std = @import("std");

pub const raylib = @import("../raylib.zig");

pub const theme = @import("theme.zig");

const interaction = @import("components/interaction.zig");

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

    pub inline fn cut(self: *Rect, side: Area, amount: f32) Rect {
        switch (side) {
            .left => return self.cutLeft(amount),
            .right => return self.cutRight(amount),
            .top => return self.cutTop(amount),
            .bottom => return self.cutBottom(amount),
            else => return self,
        }
    }

    pub inline fn getLeft(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = self.min_x,
            .min_y = self.min_y,
            .max_x = @min(self.max_x, self.min_x + amount),
            .max_y = self.max_y,
        };
    }

    pub inline fn getRight(self: Rect, amount: f32) Rect {
        return Rect{
            .min_x = @max(self.min_x, self.max_x - amount),
            .min_y = self.min_y,
            .max_x = self.max_x,
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

    pub inline fn get(self: Rect, side: Area, amount: f32) Rect {
        switch (side) {
            .left => return self.getLeft(amount),
            .right => return self.getRight(amount),
            .top => return self.getTop(amount),
            .bottom => return self.getBottom(amount),
            else => return self,
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

    pub inline fn extend(self: Rect, side: Area, amount: f32) Rect {
        switch (side) {
            .left => return self.extendLeft(amount),
            .right => return self.extendRight(amount),
            .top => return self.extendTop(amount),
            .bottom => return self.extendBottom(amount),
            else => return self,
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

    pub const InsetMode = enum {
        inner,
        outer,
    };
    pub inline fn drawLines(self: Rect, thickness: f32, color: raylib.Color, inset: InsetMode) void {
        var modified_rec = switch (inset) {
            .inner => self,
            .outer => self.extendAll(thickness),
        };
        raylib.DrawRectangleLinesEx(modified_rec.toRaylib(), thickness, color);
    }

    pub inline fn drawRoundedLines(self: Rect, thickness: f32, color: raylib.Color, inset: InsetMode) void {
        var modified_rec = switch (inset) {
            .inner => self,
            .outer => self.extendAll(thickness),
        };
        raylib.DrawRectangleRoundedLines(modified_rec.toRaylib(), 0.2, 3, thickness, color);
    }

    pub inline fn measureSize(rec: Rect, text: []const u8, font: raylib.Font, alignment: HorizontalAlignment) Rect {
        var text_rec = rec;
        const text_size = raylib.MeasureTextEx(font, text.ptr, text_rec.height(), 0.0);
        switch (alignment) {
            .left => {
                text_rec.max_x = text_rec.min_x + text_size.x;
            },
            .center => {
                text_rec.min_x = text_rec.min_x + (text_rec.width() - text_size.x) / 2;
                text_rec.max_x = text_rec.min_x + text_size.x;
            },
            .right => {
                text_rec.min_x = text_rec.max_x - text_size.x;
            },
        }
        return text_rec;
    }

    pub inline fn drawText(
        self: Rect,
        font: raylib.Font,
        text: []const u8,
        spacing: f32,
        color: raylib.Color,
        alignment: HorizontalAlignment,
    ) void {
        const text_rec = self.measureSize(text, font, alignment);

        raylib.DrawTextEx(
            font,
            text.ptr,
            .{
                .x = text_rec.min_x,
                .y = text_rec.min_y,
            },
            text_rec.height(),
            spacing,
            color,
        );
    }

    pub fn mouseWithin(self: Rect) bool {
        const mouse_pos = raylib.GetMousePosition();
        return raylib.CheckCollisionPointRec(mouse_pos, self.toRaylib());
    }

    pub fn mouseClick(self: Rect) bool {
        return self.mouseWithin() and interaction.mouseState(.pressed, null);
    }

    pub fn mouseRelease(self: Rect) bool {
        return self.mouseWithin() and interaction.mouseState(.released, null);
    }

    pub fn mouseHold(self: Rect) bool {
        return self.mouseWithin() and interaction.mouseState(.held, null);
    }

    pub const Edges = struct {
        left: Rect,
        right: Rect,
        top: Rect,
        bottom: Rect,
        top_left: Rect,
        top_right: Rect,
        bottom_left: Rect,
        bottom_right: Rect,
    };

    pub fn getEdges(self: Rect, amount: f32, expand: f32) Edges {
        return Edges{
            .left = self.getLeft(amount).extendLeft(expand),
            .right = self.getRight(amount).extendRight(expand),
            .top = self.getTop(amount).extendTop(expand),
            .bottom = self.getBottom(amount).extendBottom(expand),
            .top_left = self.getLeft(amount).getTop(amount).extendAll(expand),
            .top_right = self.getRight(amount).getTop(amount).extendAll(expand),
            .bottom_left = self.getLeft(amount).getBottom(amount).extendAll(expand),
            .bottom_right = self.getRight(amount).getBottom(amount).extendAll(expand),
        };
    }

    pub inline fn width(self: Rect) f32 {
        return self.max_x - self.min_x;
    }

    pub inline fn height(self: Rect) f32 {
        return self.max_y - self.min_y;
    }

    pub inline fn translate(self: Rect, x: f32, y: f32) Rect {
        return Rect{
            .min_x = self.min_x + x,
            .min_y = self.min_y + y,
            .max_x = self.max_x + x,
            .max_y = self.max_y + y,
        };
    }

    pub inline fn centered(self: Rect, size_x: f32, size_y: f32) Rect {
        return Rect{
            .min_x = self.min_x + (self.width() - size_x) / 2,
            .min_y = self.min_y + (self.height() - size_y) / 2,
            .max_x = self.min_x + (self.width() + size_x) / 2,
            .max_y = self.min_y + (self.height() + size_y) / 2,
        };
    }
};

pub const HorizontalAlignment = enum {
    left,
    center,
    right,
};

pub const Area = enum {
    left,
    right,
    top,
    bottom,
    top_left,
    top_right,
    bottom_left,
    bottom_right,
};

pub fn setMouseEdgeIcon(side: ?Area) void {
    if (side) |s| {
        switch (s) {
            .left => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_EW),
            .right => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_EW),
            .top => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NS),
            .bottom => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NS),
            .top_left => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NWSE),
            .top_right => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NESW),
            .bottom_left => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NESW),
            .bottom_right => raylib.SetMouseCursor(raylib.MOUSE_CURSOR_RESIZE_NWSE),
        }
    } else {
        raylib.SetMouseCursor(raylib.MOUSE_CURSOR_DEFAULT);
    }
}
