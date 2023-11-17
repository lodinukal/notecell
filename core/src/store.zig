const std = @import("std");

const math = @import("math.zig");

pub const ElementType = enum { board, card, frame, list, blob, image };

pub const Board = struct {
    name: []const u8,
};

pub const Card = struct {
    text: []const u8,
};

pub const Frame = struct {
    frame: math.Rect,
    colour: math.f4,
};

pub const List = struct {
    label: []const u8,
};

pub const Blob = struct {};

pub const Image = struct {
    image: math.Rect,
    colour: math.f4,
};

pub const Element = struct {
    extra_size: usize = 0,
    parent: ?ElementHandle = null,
    data: union(ElementType) {
        board: Board,
        card: Card,
        frame: Frame,
        list: List,
        blob: Blob,
        image: Image,
    },
};

pub const ElementHandle = struct { index: usize };

pub const ElementStore = struct {
    allocator: std.mem.Allocator,
    objects: std.ArrayListUnmanaged(Element),
    pointers: std.ArrayListUnmanaged(usize),

    pub fn create(allocator: std.mem.Allocator) !*ElementStore {
        var store = try allocator.create(ElementStore);
        store.* = try ElementStore.init(allocator);
        return store;
    }

    pub fn destroy(self: *ElementStore) void {
        self.*.deinit();
        self.allocator.destroy(self);
    }

    fn init(allocator: std.mem.Allocator) !ElementStore {
        return ElementStore{
            .allocator = allocator,
            .objects = std.ArrayListUnmanaged(Element){},
            .pointers = std.ArrayListUnmanaged(usize){},
        };
    }

    fn deinit(self: *ElementStore) void {
        self.objects.deinit(self.allocator);
        self.pointers.deinit(self.allocator);
    }

    pub fn addElement(self: *ElementStore, el: *const Element) !ElementHandle {
        const index = self.objects.items.len;
        try self.objects.append(self.allocator, el.*);
        const pointer = self.pointers.items.len;
        try self.pointers.append(self.allocator, index);
        return ElementHandle{ .index = pointer };
    }

    pub fn removeElement(self: *ElementStore, handle: ElementHandle) void {
        const index = self.pointers.items[handle.index];
        const last_index = self.pointers.getLast();

        self.objects.items[index] = self.objects.items[last_index];
        self.pointers.items[last_index] = index;

        _ = self.objects.pop();
    }

    pub fn getElement(self: *ElementStore, handle: ElementHandle) *Element {
        const index = self.pointers.items[handle.index];
        return &self.objects.items[index];
    }

    pub const Iterator = struct {
        store: *ElementStore,
        index: usize,

        pub fn next(self: *Iterator) ?ElementHandle {
            if (self.index >= self.store.pointers.items.len) {
                return null;
            }

            const index = self.store.pointers.items[self.index];
            self.index += 1;
            return ElementHandle{ .index = index };
        }
    };

    pub fn iterator(self: *ElementStore) ElementStore.Iterator {
        return ElementStore.Iterator{
            .store = self,
            .index = 0,
        };
    }

    pub const ConstIterator = struct {
        store: *const ElementStore,
        index: usize,

        pub fn next(self: *ConstIterator) ?ElementHandle {
            if (self.index >= self.store.pointers.items.len) {
                return null;
            }

            const index = self.store.pointers.items[self.index];
            self.index += 1;
            return ElementHandle{ .index = index };
        }
    };

    pub fn constIterator(self: *const ElementStore) ElementStore.ConstIterator {
        return ElementStore.ConstIterator{
            .store = self,
            .index = 0,
        };
    }

    pub const ChildrenIterator = struct {
        store: *ElementStore,
        parent: ElementHandle,

        index: usize = 0,

        pub fn next(self: *ChildrenIterator) ?ElementHandle {
            if (self.index >= self.store.pointers.items.len) {
                return null;
            }

            while (self.index < self.store.pointers.items.len) {
                const index = self.store.pointers.items[self.index];
                self.index += 1;

                const obj = self.store.objects.items[index];
                if (obj.parent != null and obj.parent.?.index == self.parent.index) {
                    return ElementHandle{ .index = index };
                }
            }
            return null;
        }
    };

    pub fn getChildren(self: *ElementStore, handle: ElementHandle) ElementStore.ChildrenIterator {
        return ElementStore.ChildrenIterator{
            .store = self,
            .parent = handle,
            .index = 0,
        };
    }

    // serialisation
    fn writeBuffer(writer: anytype, str: []const u8) !void {
        try writer.writeInt(usize, str.len, .little);
        try writer.writeAll(str);
    }

    fn writeRect(writer: anytype, rect: math.Rect) !void {
        try writer.writeInt(i32, rect.x, .little);
        try writer.writeInt(i32, rect.y, .little);
        try writer.writeInt(u32, rect.w, .little);
        try writer.writeInt(u32, rect.h, .little);
    }

    fn writeColour(writer: anytype, colour: math.f4) !void {
        try writer.writeAll(std.mem.asBytes(&colour));
    }

    pub fn write(self: *const ElementStore, writer: anytype) !void {
        try writer.writeInt(usize, self.objects.items.len, .little);
        var it = self.constIterator();
        while (it.next()) |el| {
            try writer.writeInt(u8, @intFromEnum(std.meta.activeTag(el.data)), .little);
            try writer.writeInt(u1, @intFromBool(el.parent != null), .little);
            if (el.parent) |p|
                try writer.writeInt(usize, p.index, .little);
            switch (el.data) {
                .board => |board| {
                    try writeBuffer(writer, board.name);
                },
                .card => |card| {
                    try writeBuffer(writer, card.text);
                },
                .frame => |frame| {
                    try writeRect(writer, frame.frame);
                    try writeColour(writer, frame.colour);
                },
                .list => |list| {
                    try writeBuffer(writer, list.label);
                },
                .blob => {},
                .image => |image| {
                    try writeRect(writer, image.image);
                    try writeColour(writer, image.colour);
                },
            }
        }
    }

    fn readBuffer(reader: anytype, allocator: std.mem.Allocator, str: *[]const u8) !void {
        const length = try reader.readInt(usize, .little);
        const s = try allocator.alloc(u8, length);
        _ = try reader.read(s);
        str.* = s;
    }

    fn readRect(reader: anytype, rect: *math.Rect) !void {
        rect.x = try reader.readInt(i32, .little);
        rect.y = try reader.readInt(i32, .little);
        rect.w = try reader.readInt(u32, .little);
        rect.h = try reader.readInt(u32, .little);
    }

    fn readColour(reader: anytype, colour: *math.f4) !void {
        _ = try reader.read(std.mem.asBytes(colour));
    }

    pub fn read(self: *ElementStore, reader: anytype) !void {
        const start_index = self.objects.items.len;
        const count = try reader.readInt(usize, .little);

        for (0..count) |_| {
            const elementType: ElementType = @enumFromInt(try reader.readInt(u8, .little));
            const has_parent = try reader.readInt(u8, .little) == 1;
            var parent_index: usize = 0;
            if (has_parent)
                parent_index = try reader.readInt(usize, .little);
            const parent_opt: ?ElementHandle = if (has_parent) ElementHandle{
                .index = parent_index + start_index,
            } else null;
            switch (elementType) {
                .board => {
                    var board: Board = undefined;
                    try readBuffer(reader, self.allocator, &board.name);
                    _ = try self.addElement(&Element{ .data = .{ .board = board }, .parent = parent_opt });
                },
                .card => {
                    var card: Card = undefined;
                    try readBuffer(reader, self.allocator, &card.text);
                    _ = try self.addElement(&Element{ .data = .{ .card = card }, .parent = parent_opt });
                },
                .frame => {
                    var frame: Frame = undefined;
                    try readRect(reader, &frame.frame);
                    try readColour(reader, &frame.colour);
                    _ = try self.addElement(&Element{ .data = .{ .frame = frame }, .parent = parent_opt });
                },
                .list => {
                    var list: List = undefined;
                    try readBuffer(reader, self.allocator, &list.label);
                    _ = try self.addElement(&Element{ .data = .{ .list = list }, .parent = parent_opt });
                },
                .blob => {
                    var blob: Blob = undefined;
                    _ = try self.addElement(&Element{ .data = .{ .blob = blob }, .parent = parent_opt });
                },
                .image => {
                    var image: Image = undefined;
                    try readRect(reader, &image.image);
                    try readColour(reader, &image.colour);
                    _ = try self.addElement(&Element{ .data = .{ .image = image }, .parent = parent_opt });
                },
            }
        }
    }
};

pub fn est(els: *ElementStore, el: ElementHandle, inset: usize) void {
    for (0..inset) |i| {
        _ = i;
        std.debug.print("  ", .{});
    }
    const obj = els.objects.items[els.pointers.items[el.index]];
    std.debug.print("{s}\n", .{@tagName(obj.data)});
    var it = els.getChildren(el);
    while (it.next()) |child| {
        est(els, child, inset + 1);
    }
}
