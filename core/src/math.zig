pub const v2 = @Vector(2, u32);
pub const sv2 = @Vector(2, i32);
pub const v3 = @Vector(3, u32);
pub const sv3 = @Vector(3, i32);
pub const v4 = @Vector(4, u32);
pub const sv4 = @Vector(4, i32);

pub const f4 = @Vector(4, f32);

pub const Rect = struct {
    x: i32,
    y: i32,
    w: u32,
    h: u32,

    pub fn topLeft(self: Rect) sv2 {
        return .{ self.x, self.y };
    }

    pub fn topRight(self: Rect) sv2 {
        return .{ self.x + self.w, self.y };
    }

    pub fn bottomLeft(self: Rect) sv2 {
        return .{ self.x, self.y + self.h };
    }

    pub fn bottomRight(self: Rect) sv2 {
        return .{ self.x + self.w, self.y + self.h };
    }
};
