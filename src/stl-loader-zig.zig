const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Point = struct { x: f32, y: f32, z: f32 };
pub const Vec3 = struct { i: f32, j: f32, k: f32 };

pub const Triangle = struct { v1: Point, v2: Point, v3: Point, normal: Vec3 = undefined };

/// Dispatcher for the loader function
/// Reads 5 bytes and passes reader to ascii/binary implementation
/// path is relative to cwd
pub fn load_stl(allocator: Allocator, path: []const u8) ![]Triangle {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    var headerBuffer: [5]u8 = undefined;
    _ = try reader.read(&headerBuffer);

    return switch (std.mem.eql(u8, &headerBuffer, "solid")) {
        true => {
            try file.seekTo(0);
            return try load_ascii(allocator, reader);
        },
        false => try load_binary(allocator, reader),
    };
}

/// STL loader implementation for binary STL files (first 5 bytes != solid)
/// Accepts reader 5 bytes deep into the file (see load_stl)
pub fn load_binary(allocator: Allocator, reader: anytype) ![]Triangle {
    try reader.skipBytes(75, .{});
    const facetCount = try reader.readInt(u32, .little);

    var mesh = try allocator.alloc(Triangle, facetCount);

    for (0..facetCount) |i| {
        const normal = Vec3{ .i = @as(f32, @bitCast(try reader.readInt(u32, .little))), .j = @as(f32, @bitCast(try reader.readInt(u32, .little))), .k = @as(f32, @bitCast(try reader.readInt(u32, .little))) };
        const T = Triangle{
            .v1 = Point{ .x = @as(f32, @bitCast(try reader.readInt(u32, .little))), .y = @as(f32, @bitCast(try reader.readInt(u32, .little))), .z = @as(f32, @bitCast(try reader.readInt(u32, .little))) },
            .v2 = Point{ .x = @as(f32, @bitCast(try reader.readInt(u32, .little))), .y = @as(f32, @bitCast(try reader.readInt(u32, .little))), .z = @as(f32, @bitCast(try reader.readInt(u32, .little))) },
            .v3 = Point{ .x = @as(f32, @bitCast(try reader.readInt(u32, .little))), .y = @as(f32, @bitCast(try reader.readInt(u32, .little))), .z = @as(f32, @bitCast(try reader.readInt(u32, .little))) },
            .normal = normal,
        };

        mesh[i] = T;

        try reader.skipBytes(2, .{});
    }

    return mesh;
}

/// STL loader implementation for ascii STL files (first 5 bytes = solid)
/// Accepts reader at start of file (see load_stl)
pub fn load_ascii(allocator: Allocator, reader: anytype) ![]Triangle {
    var buf_reader = std.io.bufferedReader(reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var mesh = std.ArrayList(Triangle).init(allocator);
    defer mesh.deinit();

    var o: ?[]u8 = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    loop: while (o) |_| {
        // normal
        var normal: Vec3 = undefined;
        if (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |b| {
            var coords = std.mem.splitAny(u8, b, " \r");
            if (!std.mem.eql(u8, coords.first(), "endsolid")) {
                _ = coords.next();
                normal = Vec3{ .i = try std.fmt.parseFloat(f32, coords.next().?), .j = try std.fmt.parseFloat(f32, coords.next().?), .k = try std.fmt.parseFloat(f32, coords.next().?) };
            } else {break :loop;}
        }

        o = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        // points
        var p: [3]Point = undefined;
        for (0..3) |i| {
            if (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |b| {
                var coords = std.mem.splitAny(u8, b, " \r");
                _ = coords.first();
                p[i] = Point{ .x = try std.fmt.parseFloat(f32, coords.next().?), .y = try std.fmt.parseFloat(f32, coords.next().?), .z = try std.fmt.parseFloat(f32, coords.next().?) };
        }}
        try mesh.append(Triangle{ .v1 = p[0], .v2 = p[1], .v3 = p[2], .normal = normal });

        for (0..2) |_| {  o = try in_stream.readUntilDelimiterOrEof(&buf, '\n'); }
    }
    return mesh.toOwnedSlice();
}

