const util = @import("../util.zig");
const raylib = util.raylib;

const interaction = @import("interaction.zig");

pub fn textlabel(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: util.HorizontalAlignment, color: raylib.Color) void {
    var text_rec = rec.extendAll(-8);

    rec.draw(util.theme.current_theme.foreground_color);
    rec.drawRoundedLines(2, util.theme.current_theme.secondary_outline_color, .inner);

    text_rec.drawText(
        font,
        text,
        0.0,
        color,
        alignment,
    );
}

pub fn expandText(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: util.HorizontalAlignment) util.Rect {
    var text_rec = rec.extendAll(-8);
    text_rec = text_rec.measureSize(text, font, alignment);
    return text_rec.extendAll(8);
}

pub fn textlabelExpanding(rec: util.Rect, text: []const u8, font: raylib.Font, alignment: util.HorizontalAlignment, color: raylib.Color) util.Rect {
    var draw_rec = expandText(rec, text, font, alignment);

    draw_rec.draw(util.theme.current_theme.foreground_color);
    draw_rec.drawRoundedLines(2, util.theme.current_theme.secondary_outline_color, .inner);

    draw_rec.extendAll(-8).drawText(
        font,
        text,
        0.0,
        color,
        alignment,
    );
    return draw_rec;
}

pub fn textButton(
    rec: util.Rect,
    text: []const u8,
    font: raylib.Font,
    alignment: util.HorizontalAlignment,
    color: raylib.Color,
) interaction.InteractionState {
    textlabel(rec, text, font, alignment, color);
    return interaction.interactor(rec);
}

pub fn textButtonExpanding(
    rec: util.Rect,
    text: []const u8,
    font: raylib.Font,
    alignment: util.HorizontalAlignment,
    color: raylib.Color,
    level: interaction.ButtonLevel,
) interaction.InteractionState {
    var draw_rec = expandText(rec, text, font, alignment);
    const state = interaction.interactor(draw_rec);

    draw_rec.draw(interaction.colorFromStates(level, state));
    draw_rec.drawRoundedLines(2, interaction.outlineColorFromLevel(level), .inner);

    draw_rec.extendAll(-8).drawText(font, text, 0.0, color, alignment);

    return state;
}
