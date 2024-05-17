const std = @import("std");
const Lexer = @import("./Lexer.zig");
const Token = @import("./Token.zig");

pub fn main() !void {
    const input =
        \\local firstName = "Joshua"
        \\local lastName = 'Jones'
        \\function name()
        \\  return 1 + 1
        \\end
    ;
    var lexer = Lexer.init(input);
    var i: u32 = 0;
    while (i <= input.len) : (i += 1) {
        const token = lexer.advance().?;
        std.debug.print("Type: {?}\n", .{token});
        if (token.kind == Token.Kind.Eof) {
            break;
        }
    }
}
