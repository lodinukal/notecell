const util = @import("../util.zig");
const raylib = util.raylib;

const interaction = @import("interaction.zig");

pub const TextAlignment = enum(u8) {
    left,
    center,
    right,
};

pub inline fn measureSize(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: TextAlignment) util.Rect {
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

pub fn textlabel(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: TextAlignment, color: raylib.Color) void {
    var text_rec = rec.extendAll(-8);
    text_rec = measureSize(text_rec, text, font, alignment);

    rec.draw(util.theme.current_theme.foreground_color);
    rec.drawRoundedLines(2, util.theme.current_theme.secondary_outline_color, .inner);

    text_rec.drawText(
        font,
        text,
        0.0,
        color,
    );
}

pub fn expandText(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: TextAlignment) util.Rect {
    var text_rec = rec.extendAll(-8);
    text_rec = measureSize(text_rec, text, font, alignment);
    return text_rec.extendAll(8);
}

pub fn textlabelExpanding(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: TextAlignment, color: raylib.Color) util.Rect {
    var draw_rec = expandText(rec, text, font, alignment);

    draw_rec.draw(util.theme.current_theme.foreground_color);
    draw_rec.drawRoundedLines(2, util.theme.current_theme.secondary_outline_color, .inner);

    draw_rec.extendAll(-8).drawText(
        font,
        text,
        0.0,
        color,
    );
    return draw_rec;
}

pub fn textButton(
    rec: util.Rect,
    text: []const u8,
    font: raylib.Font,
    alignment: TextAlignment,
    color: raylib.Color,
) interaction.InteractionState {
    textlabel(rec, text, font, alignment, color);
    return interaction.interactor(rec);
}

pub fn textButtonExpanding(
    rec: util.Rect,
    text: []const u8,
    font: raylib.Font,
    alignment: TextAlignment,
    color: raylib.Color,
    level: interaction.ButtonLevel,
) interaction.InteractionState {
    var draw_rec = expandText(rec, text, font, alignment);
    const state = interaction.interactor(draw_rec);

    draw_rec.draw(interaction.colorFromStates(level, state));
    draw_rec.drawRoundedLines(2, interaction.outlineColorFromLevel(level), .inner);

    draw_rec.extendAll(-8).drawText(
        font,
        text,
        0.0,
        color,
    );

    return state;
}
