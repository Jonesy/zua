const std = @import("std");

pub const TokenValue = union(enum) {
    none,
    number: f64,
    string: []const u8,
    boolean: bool,
};

const Token = @This();

kind: Kind,
start: usize,
end: usize,
value: TokenValue = undefined,

pub const Kind = enum {
    Skip, // Whitespace
    Eof, // End of File
    // Values
    Identifier, // eg. local name
    Numeral, // int          ^^^^
    String, // single line string
    MultiLineString, // Multiline string

    // Keywords
    And, // and
    Break, // break
    Do, // do
    Else, // else
    ElseIf, // elseif
    End, // end
    False, // false
    For, // for
    Function, // function
    GoTo, // goto
    If, // if
    In, // in
    Local, // local
    Nil, // nil
    Not, // not
    Or, // or
    Repeat, // repeat
    Return, // return
    Then, // then
    True, // true
    Until, // until
    While, // while
    // Symbols
    Plus, // +
    Subtract, // -
    Multiply, // *
    Divide, // /
    Modulo, // %
    Pow, // ^
    Length, // #
    BitwiseAnd, // &
    BitwiseNot, // ~
    BitwiseOr, // |
    BitwiseLeft, // <<
    BitwiseRight, // >>
    FloorDivide, // //
    Equals, // ==
    Inequal, // ~=
    LtEqual, // <=
    GtEqual, // >=
    Lt, // <
    Gt, // >
    Equal, // =
    LParen, // (
    RParen, // )
    LBrace, // {
    RBrace, // }
    LBracket, // [
    RBracket, // ]
    Label, // ::
    Semicolon, // ;
    Colon, // :
    Comma, // ,
    Dot, // .
    Concat, // ..
    Spread, // ...

    pub fn has_token_value(self: Kind) bool {
        return switch (self) {
            .Identifier,
            .Numeral,
            .String,
            .MultiLineString,
            .Boolean,
            => true,
            _ => false,
        };
    }
};
