const raylib = @import("../raylib.zig");

const util = @import("../util.zig");

const rgb = util.rgb;

pub const FontSet = struct {
    name: []const u8,
    loaded: ?raylib.Font = null,
};

pub const Style = struct {
    background_color: raylib.Color = rgb(0, 0, 0),
    foreground_color: raylib.Color = rgb(0, 0, 0),
    escape_color: raylib.Color = rgb(0, 0, 0),
    regular_font: FontSet = .{
        .name = "./resources/JetBrainsMonoNL-Regular.ttf",
    },
    bold_font: FontSet = .{
        .name = "./resources/JetBrainsMonoNL-Bold.ttf",
    },
    italic_font: FontSet = .{
        .name = "./resources/JetBrainsMonoNL-Italic.ttf",
    },
    main_text_color: raylib.Color = rgb(255, 255, 255),
    focus_text_color: raylib.Color = rgb(255, 255, 255),
    secondary_text_color: raylib.Color = rgb(255, 255, 255),
    main_text_color_dim: raylib.Color = rgb(255, 255, 255),
    grid_color: raylib.Color = rgb(255, 255, 255),
    main_outline_color: raylib.Color = rgb(255, 255, 255),
    secondary_outline_color: raylib.Color = rgb(255, 255, 255),
    primary_button_color: raylib.Color = rgb(255, 255, 255),
    primary_button_hover_color: raylib.Color = rgb(255, 255, 255),
    primary_button_pressed_color: raylib.Color = rgb(255, 255, 255),
    primary_button_outline_color: raylib.Color = rgb(255, 255, 255),
    secondary_button_color: raylib.Color = rgb(255, 255, 255),
    secondary_button_hover_color: raylib.Color = rgb(255, 255, 255),
    secondary_button_pressed_color: raylib.Color = rgb(255, 255, 255),
    secondary_button_outline_color: raylib.Color = rgb(255, 255, 255),
};

pub var dark = Style{
    .background_color = rgb(20, 20, 20),
    .foreground_color = rgb(30, 30, 30),
    .escape_color = .{
        .a = 100,
        .r = 0,
        .g = 0,
        .b = 0,
    },
    .main_text_color = rgb(200, 200, 200),
    .focus_text_color = rgb(250, 250, 250),
    .secondary_text_color = rgb(150, 150, 150),
    .main_text_color_dim = rgb(120, 120, 120),
    .grid_color = util.fromHex(0x33333355),
    .main_outline_color = rgb(50, 50, 50),
    .secondary_outline_color = rgb(40, 40, 40),
    .primary_button_color = rgb(45, 45, 45),
    .primary_button_hover_color = rgb(55, 55, 55),
    .primary_button_pressed_color = rgb(65, 65, 65),
    .primary_button_outline_color = rgb(35, 35, 35),
    .secondary_button_color = rgb(35, 35, 35),
    .secondary_button_hover_color = rgb(45, 45, 45),
    .secondary_button_pressed_color = rgb(55, 55, 55),
    .secondary_button_outline_color = rgb(25, 25, 25),
};
pub var light = Style{};

pub var current_theme: *const Style = &dark;

pub fn setTheme(theme: *Style) void {
    current_theme = theme;

    inline for (.{
        "regular_font", "bold_font", "italic_font",
    }) |member_name| {
        const font_set: *FontSet = &@field(theme, member_name);
        if (font_set.loaded == null) {
            font_set.loaded = raylib.LoadFont(font_set.name.ptr);
            raylib.SetTextureFilter(font_set.loaded.?.texture, raylib.TEXTURE_FILTER_BILINEAR);
        }
    }
}
