const std = @import("std");
pub fn main() !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("foo.txt", .{});
    defer file.close();
}
