const std = @import("std");
const Lexer = @import("./Lexer.zig");
const Token = @import("./Token.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const file_name = args[1];
    const max_size = std.math.maxInt(usize);
    const file = try std.fs.cwd().readFileAlloc(allocator, file_name, max_size);
    defer allocator.free(file);

    var lexer = Lexer.init(file);
    var i: u32 = 0;
    while (i <= file.len) : (i += 1) {
        const token = lexer.advance().?;
        std.debug.print("Type: {?}\n", .{token});
        if (token.kind == Token.Kind.Eof) {
            break;
        }
    }
}
