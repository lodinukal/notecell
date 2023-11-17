const std = @import("std");
const testing = std.testing;

const store = @import("store.zig");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "store" {
    _ = store;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var s = try store.ElementStore.create(allocator);
    defer s.destroy();

    const ser = false;

    if (ser) {
        var board = try s.addElement(&.{ .data = .{ .board = .{ .name = "board" } } });

        var card = try s.addElement(&.{ .data = .{ .card = .{ .text = "card" } }, .parent = board });
        var card2 = try s.addElement(&.{ .data = .{ .card = .{ .text = "card" } }, .parent = board });
        _ = card2;

        var frame = try s.addElement(&.{
            .data = .{
                .frame = .{
                    .frame = .{ .x = 0, .y = 0, .w = 100, .h = 100 },
                    .colour = .{ 1, 1, 1, 1 },
                },
            },
            .parent = card,
        });
        _ = frame;

        var file = try std.fs.cwd().createFile("test.ncell", .{ .read = true, .exclusive = true });
        defer file.close();

        try s.write(file.writer());
    } else {
        var file = try std.fs.cwd().openFile("test.ncell", .{});
        defer file.close();

        try s.read(file.reader());
        try file.seekTo(0);
        try s.read(file.reader());

        var it = s.constIterator();
        while (it.next()) |e| {
            // top level
            const obj = s.getElement(e);
            if (obj.parent == null) {
                store.est(s, e, 0);
            }
        }

        std.debug.print("len: {}\n", .{s.objects.items.len});
    }

    // var value = try store.get(handle, u32);

    // try testing.expectEqual(@as(u32, 42), value.*);
}
