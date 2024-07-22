const std = @import("std");
const stlLoader = @import("stl_loader");

pub fn main() !void {
    // path relative to cwd
    const filepath: []const u8 = "file.stl";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const mesh = try stlLoader.load_stl(allocator, filepath);
    defer allocator.free(mesh);

    // read mesh from end to start
    var t: stlLoader.Triangle = undefined;
    var i = mesh.len - 1;
    while (true) {
        t = mesh[i];
        std.debug.print("Triangle {d}:\n{d} {d} {d}\n", .{ i, t.v1.x, t.v1.y, t.v1.z });
        std.debug.print("{d} {d} {d}\n", .{ t.v2.x, t.v2.y, t.v2.z });
        std.debug.print("{d} {d} {d}\n", .{ t.v3.x, t.v3.y, t.v3.z });
        if (i > 0) {
            i -= 1;
        } else {
            break;
        }
    }
}
