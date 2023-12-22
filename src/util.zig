const raylib = @import("raylib.zig");

pub inline fn fromHex(hex: u32) raylib.Color {
    return raylib.Color{
        .r = (hex >> 24) & 0xFF,
        .g = (hex >> 16) & 0xFF,
        .b = (hex >> 8) & 0xFF,
        .a = hex & 0xFF,
    };
}

pub inline fn rgb(r: u8, g: u8, b: u8) raylib.Color {
    return raylib.Color{
        .r = r,
        .g = g,
        .b = b,
        .a = 255,
    };
}
