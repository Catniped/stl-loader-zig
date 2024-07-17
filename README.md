# stl-loader-zig

A tiny simple zig library for loading STL files with support for both ASCII and binary representations. 

## Usage
Currently to use the library you need to include the file in your project by downloading it and copying it alongside your source code. This may change when i get more familiar with zigs packaging system.

Example usage provided in [example.zig](src/example.zig):

```c
const stlLoader = @import("./stl-loader-zig.zig");
const Allocator = std.mem.Allocator;

...

const filepath: []const u8 = "file.stl";

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
defer _ = gpa.deinit();

const mesh = try stlLoader.load_stl(allocator, filepath);
defer allocator.free(mesh);
// do stuff with mesh
```

Loading by default should be done thru dispatcher function, which takes a path for the file **relative to the cwd** and automatically chooses which implementation of the reader to use. If the type of the STL file is known at compile time, or you wish to dispatch the functions manually, **note the offsets for the reader required before calling the functions.**

## Notes
- At the time of writing this, I am still quite new to zig, so the code may not be perfect. Feel free to suggest improvements and bugfixes in the GitHub issues!