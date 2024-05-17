const std = @import("std");
const Chars = @import("./Chars.zig");
const Token = @import("./Token.zig");

const Kind = Token.Kind;
const TokenValue = Token.TokenValue;
const testing = std.testing;

const Lexer = @This();

// Input text, can be from file
source: []const u8,
// Chars slice iterates over each u8
chars: Chars,

pub fn init(source: []const u8) Lexer {
    return Lexer{
        .source = source,
        .chars = Chars.init(source),
    };
}

fn match_keyword(self: *Lexer) Kind {
    const start: usize = self.chars.index - 1;
    var end: usize = start;

    for (self.chars.bytes[start..]) |char| {
        if (!std.ascii.isAlphanumeric(char)) break;
        end += 1;
    }

    const slice = self.chars.bytes[start..end];
    self.chars.take(slice.len - 1);
    inline for (@typeInfo(Kind).Enum.fields) |f| {
        if (std.ascii.eqlIgnoreCase(f.name, slice)) {
            return @enumFromInt(f.value);
        }
    }

    // TODO: Parse the value of the identifier
    return Kind.Identifier;
}

pub fn match_string(self: *Lexer, quote_type: u8) Kind {
    // Start is advanced 1 from the intercepted quote char, eg
    // "hello"
    // 0^23456
    const start: usize = self.chars.index;
    var end: usize = start;

    // Stop once the terminating quote is reached
    for (self.chars.bytes[start..]) |char| {
        end += 1;
        if (char == quote_type) break;
    }
    // Increment the end one more slice
    // "hello"
    // 012345^
    // S123456
    const slice_start: usize = start - 1;
    const slice = self.chars.bytes[slice_start..end];
    self.chars.take(slice.len - 1);

    return Kind.String;
}

pub fn read_next_kind(self: *Lexer) Kind {
    while (self.chars.next()) |char| {
        return switch (char) {
            'a'...'z' => keyword: {
                break :keyword self.match_keyword();
            },
            '"' => self.match_string('"'),
            '\'' => self.match_string('\''),
            // TODO: Handle numbers (same as string)
            '0'...'9' => Kind.Numeral,
            '+' => Kind.Plus,
            '-' => Kind.Subtract,
            '*' => Kind.Multiply,
            '/' => divide: {
                switch (self.peek()) {
                    '/' => {
                        self.chars.take(1);
                        break :divide Kind.FloorDivide;
                    },
                    else => {},
                }
                return Kind.Divide;
            },
            '%' => Kind.Modulo,
            '^' => Kind.Pow,
            '#' => Kind.Length,
            '&' => Kind.BitwiseAnd,
            '~' => tilde: {
                switch (self.peek()) {
                    '=' => {
                        self.chars.take(1);
                        break :tilde Kind.Inequal;
                    },
                    else => {},
                }
                break :tilde Kind.BitwiseNot;
            },
            '|' => Kind.BitwiseOr,
            '<' => lt: {
                switch (self.peek()) {
                    '<' => {
                        self.chars.take(1);
                        break :lt Kind.BitwiseLeft;
                    },
                    '=' => {
                        self.chars.take(1);
                        break :lt Kind.LtEqual;
                    },
                    else => {},
                }
                break :lt Kind.Lt;
            },
            '>' => gt: {
                switch (self.peek()) {
                    '>' => {
                        self.chars.take(1);
                        break :gt Kind.BitwiseRight;
                    },
                    '=' => {
                        self.chars.take(1);
                        break :gt Kind.GtEqual;
                    },
                    else => {},
                }
                break :gt Kind.Gt;
            },
            '=' => equal: {
                switch (self.peek()) {
                    '=' => {
                        self.chars.take(1);
                        break :equal Kind.Equals;
                    },
                    else => {},
                }
                break :equal Kind.Equal;
            },
            '(' => Kind.LParen,
            ')' => Kind.RParen,
            '{' => Kind.LBrace,
            '}' => Kind.RBrace,
            '[' => Kind.LBracket,
            ']' => Kind.RBracket,
            ';' => Kind.Semicolon,
            ',' => Kind.Comma,
            ':' => colon: {
                switch (self.peek()) {
                    ':' => {
                        self.chars.take(1);
                        break :colon Kind.Label;
                    },
                    else => {},
                }
                break :colon Kind.Colon;
            },
            '.' => dot: {
                switch (self.peek()) {
                    '.' => {
                        switch (self.peek2()) {
                            '.' => {
                                self.chars.take(2);
                                break :dot Kind.Spread;
                            },
                            else => {
                                self.chars.take(1);
                                break :dot Kind.Concat;
                            },
                        }
                    },
                    else => {},
                }
                break :dot Kind.Dot;
            },
            else => Kind.Skip,
        };
    }
    return Token.Kind.Eof;
}

pub fn parse_value(self: *Lexer, kind: Kind, start: usize, end: usize) TokenValue {
    return switch (kind) {
        .String => {
            const slice = self.chars.bytes[start..end];
            return TokenValue{
                .string = slice[1..(slice.len - 1)],
            };
        },
        .True => TokenValue{ .boolean = true },
        .False => TokenValue{ .boolean = false },
        .Numeral => TokenValue{
            // TODO: Parse to a number
            .number = 0,
        },
        .Identifier => TokenValue{
            .string = self.chars.bytes[start..end],
        },
        else => TokenValue{ .none = undefined },
    };
}

pub fn advance(self: *Lexer) ?Token {
    const start = self.offset();
    const kind = self.read_next_kind();
    const end = self.offset();
    const value = self.parse_value(kind, start, end);

    return Token{
        .kind = kind,
        .start = start,
        .end = end,
        .value = value,
    };
}

pub fn peek(self: *Lexer) u8 {
    var copy = self.chars;
    return copy.next() orelse 0;
}

pub fn peek2(self: *Lexer) u8 {
    var copy = self.chars;
    const n = copy.next();
    _ = n;
    return copy.next() orelse 0;
}

pub fn offset(self: *Lexer) usize {
    return self.source.len - self.chars.len;
}

test "it advances" {
    const input = "+";
    var lexer = Lexer.init(input);
    try testing.expectEqual(Token{ .start = 0, .end = 1, .kind = Kind.Plus }, lexer.advance().?);
    try testing.expectEqual(Token{ .start = 1, .end = 1, .kind = Kind.Eof }, lexer.advance().?);
}

test "2 char input" {
    const input = "==";
    var lexer = Lexer.init(input);
    try testing.expectEqual(Token{ .start = 0, .end = 2, .kind = Kind.Equals }, lexer.advance().?);
    try testing.expectEqual(Token{ .start = 2, .end = 2, .kind = Kind.Eof }, lexer.advance().?);
}

test "splits a 3 char input with 2 tokens" {
    const input = "===";
    var lexer = Lexer.init(input);
    try testing.expectEqual(Token{ .start = 0, .end = 2, .kind = Kind.Equals }, lexer.advance().?);
    try testing.expectEqual(Token{ .start = 2, .end = 3, .kind = Kind.Equal }, lexer.advance().?);
    try testing.expectEqual(Token{ .start = 3, .end = 3, .kind = Kind.Eof }, lexer.advance().?);
}

test "a 3-char input" {
    const input = "...";
    var lexer = Lexer.init(input);
    try testing.expectEqual(Token{ .start = 0, .end = 3, .kind = Kind.Spread }, lexer.advance().?);
    try testing.expectEqual(Token{ .start = 3, .end = 3, .kind = Kind.Eof }, lexer.advance().?);
}

test "all symbols" {
    const input =
        \\+
        \\-
        \\*
        \\/
        \\%
        \\^
        \\#
        \\&
        \\~
        \\|
        \\<<
        \\>>
        \\//
        \\==
        \\~=
        \\<=
        \\>=
        \\<
        \\>
        \\=
        \\(
        \\)
        \\{
        \\}
        \\[
        \\]
        \\::
        \\;
        \\:
        \\,
        \\.
        \\..
        \\...
    ;
    var lexer = Lexer.init(input);
    const kinds = [_]Kind{
        Kind.Plus,
        Kind.Subtract,
        Kind.Multiply,
        Kind.Divide,
        Kind.Modulo,
        Kind.Pow,
        Kind.Length,
        Kind.BitwiseAnd,
        Kind.BitwiseNot,
        Kind.BitwiseOr,
        Kind.BitwiseLeft,
        Kind.BitwiseRight,
        Kind.FloorDivide,
        Kind.Equals,
        Kind.Inequal,
        Kind.LtEqual,
        Kind.GtEqual,
        Kind.Lt,
        Kind.Gt,
        Kind.Equal,
        Kind.LParen,
        Kind.RParen,
        Kind.LBrace,
        Kind.RBrace,
        Kind.LBracket,
        Kind.RBracket,
        Kind.Label,
        Kind.Semicolon,
        Kind.Colon,
        Kind.Comma,
        Kind.Dot,
        Kind.Concat,
        Kind.Spread,
    };
    for (kinds) |expected| {
        const token = lexer.advance().?;
        try testing.expectEqual(expected, token.kind);
        const skip = lexer.advance().?;
        _ = skip;
    }
}

test "handles keywords" {
    const input =
        \\and
        \\break
        \\do
        \\else
        \\elseif
        \\end
        \\false
        \\for
        \\function
        \\goto
        \\if
        \\in
        \\local
        \\nil
        \\not
        \\or
        \\repeat
        \\return
        \\then
        \\true
        \\until
        \\while
    ;
    const kinds = [_]Kind{
        Kind.And,
        Kind.Break,
        Kind.Do,
        Kind.Else,
        Kind.ElseIf,
        Kind.End,
        Kind.False,
        Kind.For,
        Kind.Function,
        Kind.GoTo,
        Kind.If,
        Kind.In,
        Kind.Local,
        Kind.Nil,
        Kind.Not,
        Kind.Or,
        Kind.Repeat,
        Kind.Return,
        Kind.Then,
        Kind.True,
        Kind.Until,
        Kind.While,
    };
    var lexer = Lexer.init(input);
    for (kinds) |expected| {
        const token = lexer.advance().?;
        try testing.expectEqual(expected, token.kind);
        const skip = lexer.advance().?;
        _ = skip;
    }
}

test "handles strings" {
    const input =
        \\"hello" 'world' ""
    ;
    var lexer = Lexer.init(input);
    const hello = lexer.advance().?;
    try testing.expect(hello.kind == Kind.String);
    try testing.expect(hello.start == 0);
    try testing.expect(hello.end == 7);
    try testing.expectEqualStrings(hello.value.string, "hello");

    _ = lexer.advance().?;
    const world = lexer.advance().?;
    try testing.expect(world.kind == Kind.String);
    try testing.expect(world.start == 8);
    try testing.expect(world.end == 15);
    try testing.expectEqualStrings(world.value.string, "world");

    _ = lexer.advance().?;
    const empty = lexer.advance().?;
    try testing.expect(empty.kind == Kind.String);
    try testing.expect(empty.start == 16);
    try testing.expect(empty.end == 18);
    try testing.expect(empty.value.string.len == 0);
}
