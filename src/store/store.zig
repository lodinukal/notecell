const std = @import("std");

const json = std.json;

const util = @import("../util.zig");

pub const Project = struct {
    const Serialised = struct {
        name: []const u8 = "untitled",
        main_scene_name: []const u8 = "main.json",
        scenes_dir_path: []const u8 = "./scenes",
        content_dir_path: []const u8 = "./content",
    };
    const stringify_options = json.StringifyOptions{
        .whitespace = .indent_4,
        .emit_null_optional_fields = true,
        .emit_nonportable_numbers_as_strings = true,
    };

    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    arena_allocator: std.mem.Allocator,
    name: []const u8,
    name_owned: bool,
    serve_dir: std.fs.Dir,

    main_scene_name: ?[]const u8,
    scenes_dir: ?std.fs.Dir,
    scenes_dir_path: ?[]const u8,
    content_dir: ?std.fs.Dir,
    content_dir_path: ?[]const u8,
    current_loaded_scene: ?*Scene,

    pub fn createWithServeDir(allocator: std.mem.Allocator, dir: std.fs.Dir, name: ?[]const u8) !*Project {
        var project: *Project = try allocator.create(Project);
        project.allocator = allocator;
        project.arena = std.heap.ArenaAllocator.init(allocator);
        project.arena_allocator = project.arena.allocator();
        project.serve_dir = dir;
        project.name = name orelse "untitled";
        project.name_owned = false;

        project.main_scene_name = null;
        project.scenes_dir = null;
        project.scenes_dir_path = null;
        project.content_dir = null;
        project.content_dir_path = null;
        project.current_loaded_scene = null;

        try project.readProjectOrInit();
        project.current_loaded_scene = try project.loadOrCreateScene(project.main_scene_name.?);

        std.debug.print("cards: {}\n", .{project.current_loaded_scene.?.cards.items.len});

        return project;
    }

    pub const ProjectError = error{
        ProjectManifestNotFound,
        ProjectUnableToReadManifest,
        ProjectCouldNotOpenContentDir,
        ProjectCouldNotOpenScenesDir,
        ProjectCouldNotReadMainScene,
        ProjectUnableToWriteManifest,
    };

    pub const project_manifest_name = "project.json";
    pub fn readProject(self: *Project) ProjectError!void {
        var file = self.serve_dir.openFile(project_manifest_name, std.fs.File.OpenFlags{
            .mode = .read_only,
        }) catch return error.ProjectManifestNotFound;
        defer file.close();

        const data = file.reader().readAllAlloc(self.arena_allocator, 4096) catch
            return error.ProjectUnableToReadManifest;
        defer self.arena_allocator.free(data);

        const doc = json.parseFromSliceLeaky(Serialised, self.arena_allocator, data, .{}) catch
            return error.ProjectUnableToReadManifest;
        try self.emplaceSerialisable(doc);
    }

    pub fn initProject(self: *Project) !void {
        try self.emplaceSerialisable(.{});
    }

    fn writeProject(self: *Project) !void {
        var file = self.serve_dir.createFile(project_manifest_name, std.fs.File.CreateFlags{
            .read = true,
            .exclusive = true,
        }) catch |err| switch (err) {
            error.PathAlreadyExists => self.serve_dir.openFile(project_manifest_name, std.fs.File.OpenFlags{
                .mode = .write_only,
            }) catch |inner_err| switch (inner_err) {
                else => return error.ProjectUnableToWriteManifest,
            },
            else => return error.ProjectUnableToWriteManifest,
        };
        defer file.close();

        var default = Serialised{
            .name = self.name,
        };
        if (self.main_scene_name) |name| {
            default.main_scene_name = name;
        }
        if (self.scenes_dir_path) |path| {
            default.scenes_dir_path = path;
        }
        if (self.content_dir_path) |path| {
            default.content_dir_path = path;
        }

        try json.stringify(default, stringify_options, file.writer());
    }

    fn ensuredOpenDir(self: *Project, dir: ?std.fs.Dir, name: []const u8) !std.fs.Dir {
        return dir orelse self.serve_dir.openDir(name, .{}) catch blk: {
            self.serve_dir.makePath(name) catch {};
            break :blk try self.serve_dir.openDir(name, .{});
        };
    }

    fn emplaceSerialisable(self: *Project, ser: Serialised) !void {
        self.scenes_dir_path = self.arena_allocator.dupe(u8, ser.scenes_dir_path) catch null;
        self.content_dir_path = self.arena_allocator.dupe(u8, ser.content_dir_path) catch null;

        self.scenes_dir = self.ensuredOpenDir(self.scenes_dir, ser.scenes_dir_path) catch null;
        self.content_dir = self.ensuredOpenDir(self.content_dir, ser.content_dir_path) catch null;
        self.main_scene_name = self.arena_allocator.dupe(u8, ser.main_scene_name) catch null;

        if (self.scenes_dir == null) return error.ProjectCouldNotOpenScenesDir;
        if (self.content_dir == null) return error.ProjectCouldNotOpenContentDir;
        if (self.main_scene_name == null) return error.ProjectCouldNotReadMainScene;
    }

    pub fn readProjectOrInit(self: *Project) !void {
        self.readProject() catch |err| switch (err) {
            ProjectError.ProjectManifestNotFound => try self.initProject(),
            else => return err,
        };
        try self.writeProject();
    }

    pub fn destroy(self: *Project) void {
        self.deinit();
        self.allocator.destroy(self);
    }

    pub fn deinit(self: *Project) void {
        if (self.current_loaded_scene) |scene| {
            self.writeScene(scene.name, scene) catch {};
            scene.destroy();
            self.current_loaded_scene = null;
        }
        if (self.scenes_dir) |*dir| {
            dir.close();
        }
        if (self.content_dir) |*dir| {
            dir.close();
        }
        self.arena.deinit();
    }

    // reading scenes
    fn loadScene(self: *Project, name: []const u8) !*Scene {
        var file = self.scenes_dir.?.openFile(name, std.fs.File.OpenFlags{
            .mode = .read_only,
        }) catch return error.SceneNotFound;
        defer file.close();

        const data = file.reader().readAllAlloc(self.arena_allocator, std.math.maxInt(u32)) catch
            return error.ProjectUnableToReadManifest;
        defer self.arena_allocator.free(data);

        const value = try std.json.parseFromSlice(json.Value, self.arena_allocator, data, .{});
        const scene = try std.json.parseFromValueLeaky(*Scene, self.arena_allocator, value.value, .{});
        scene.allocator = self.arena_allocator;
        return scene;
    }

    fn writeScene(self: *Project, name: []const u8, scene: *Scene) !void {
        var file = self.scenes_dir.?.createFile(name, std.fs.File.CreateFlags{
            .read = true,
            .exclusive = true,
        }) catch |err| switch (err) {
            error.PathAlreadyExists => self.scenes_dir.?.openFile(name, std.fs.File.OpenFlags{
                .mode = .write_only,
            }) catch |inner_err| switch (inner_err) {
                else => return error.SceneUnableToWriteToExisting,
            },
            else => return error.SceneUnableToWrite,
        };
        defer file.close();

        try std.json.stringify(scene, stringify_options, file.writer());
    }

    fn loadOrCreateScene(self: *Project, name: []const u8) !*Scene {
        const scene = self.loadScene(name) catch |err| switch (err) {
            error.SceneNotFound => blk: {
                const created_scene = try self.arena_allocator.create(Scene);
                created_scene.allocator = self.arena_allocator;
                created_scene.name = try self.arena_allocator.dupe(u8, name);
                created_scene.cards = std.ArrayList(Card).init(self.arena_allocator);
                break :blk created_scene;
            },
            else => return err,
        };
        try self.writeScene(name, scene);
        return scene;
    }
};

fn getOrDefaultKeyString(map: json.ObjectMap, key: []const u8, default_value: []const u8) []const u8 {
    return (map.get(key) orelse json.Value{ .string = default_value }).asString() catch
        return default_value;
}

fn getOrDefaultKeyFloat(map: json.ObjectMap, key: []const u8, default_value: f64) f64 {
    return (map.get(key) orelse json.Value{ .float = default_value }).asFloat() catch
        return default_value;
}

fn getOrDefaultKeyInt(map: json.ObjectMap, key: []const u8, default_value: u32) u32 {
    return (map.get(key) orelse json.Value{ .int = default_value }).asInt() catch
        return default_value;
}

fn getOrNullKey(map: json.ObjectMap, key: []const u8) ?json.Value {
    return map.get(key);
}

pub const Scene = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    cards: std.ArrayList(Card),

    pub fn deinit(self: *Scene) void {
        self.allocator.free(self.name);
        self.cards.deinit();
    }

    pub fn destroy(self: *Scene) void {
        self.deinit();
        self.allocator.destroy(self);
    }

    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("name");
        try jws.write(value.name);
        try jws.objectField("cards");
        try jws.write(value.cards.items);
        try jws.endObject();
    }

    pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) !@This() {
        if (source != .object) return error.UnexpectedToken;
        const name = source.object.get("name") orelse return error.UnexpectedToken;
        if (name != .string) return error.UnexpectedToken;
        const cards = source.object.get("cards") orelse return error.UnexpectedToken;
        if (cards != .array) return error.UnexpectedToken;

        var scene = Scene{
            .allocator = allocator,
            .name = try allocator.dupe(u8, name.string),
            .cards = try std.ArrayList(Card).initCapacity(allocator, cards.array.items.len),
        };

        var child_options = options;
        child_options.ignore_unknown_fields = true;
        for (cards.array.items) |raw_card| {
            const card = try json.parseFromValue(Card, allocator, raw_card, child_options);
            scene.cards.appendAssumeCapacity(card.value);
        }

        return scene;
    }
};

pub const Card = struct {
    name: []const u8,
    rect: Area,
    color: [4]u8,
    // inner: union(enum) {
    //     board: Board,
    //     note: Note,
    //     column: Column,
    // },
};

pub const Board = struct {
    resource: ResourceId,
};

pub const Note = struct {
    allocator: std.mem.Allocator,
    content: []const u8,
    formatting: void = {},

    pub fn deinit(self: *Note) void {
        self.allocator.free(self.content);
    }
};

pub const Column = struct {
    allocator: std.mem.Allocator,
    cards: std.ArrayList(Card),

    pub fn deinit(self: *Column) void {
        self.cards.deinit();
    }
};

pub const ResourceId = struct {
    allocator: ?std.mem.Allocator,
    path: []const u8,

    pub fn deinit(self: *ResourceId) void {
        (self.allocator orelse return).free(self.path);
    }
};

pub const Area = struct {
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,

    pub inline fn width(self: Area) f32 {
        return self.max_x - self.min_x;
    }

    pub inline fn height(self: Area) f32 {
        return self.max_y - self.min_y;
    }

    pub inline fn center(self: Area) [2]f32 {
        return .{
            self.min_x + self.width() / 2.0,
            self.min_y + self.height() / 2.0,
        };
    }

    pub inline fn contains(self: Area, point: [2]f32) bool {
        return point[0] >= self.min_x and point[0] <= self.max_x and
            point[1] >= self.min_y and point[1] <= self.max_y;
    }

    pub inline fn contains_area(self: Area, other: Area) bool {
        return other.min_x >= self.min_x and other.max_x <= self.max_x and
            other.min_y >= self.min_y and other.max_y <= self.max_y;
    }
};

pub fn InBoardHandle(comptime T: type) type {
    _ = T;

    return struct {
        id: u32,
    };
}
