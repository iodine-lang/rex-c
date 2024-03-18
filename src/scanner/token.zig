// @author: ruka-lang
// @created: 2024-03-04

const rukac = @import("../root.zig");
const util = rukac.util;

const std = @import("std");

/// Represents a lexeme: it's kind, file, and position within that file
pub const Token = struct {
    kind: Kind,
    file: []const u8,
    pos: util.Position,
    /// Creates a new token
    pub fn init(kind: Kind, file: []const u8, pos: util.Position) Token {
        return Token {
            .kind = kind,
            .file = file,
            .pos = pos
        };
    }
};

/// Represents the kind of lexeme and corresponding value when applicable
pub const Kind = union(enum) {
    Identifier: []const u8,
    String: []const u8,
    Character: u8,
    Integer: []const u8,
    Float: []const u8,
    Keyword: Keyword,
    Mode: Mode,
    // Assignment
    Assign,        // =
    AssignExp,     // :=
    // Punctuation
    Dot,           // .
    Comma,         // ,
    Lparen,        // (
    Rparen,        // )
    Lbracket,      // [
    Rbracket,      // ]
    Lsquirly,      // {
    Rsquirly,      // }
    Quote,         // '
    Dblquote,      // "
    Backtick,      // `
    Backslash,     // \
    Colon,         // :
    Semicolon,     // ;
    Arrow,         // ->
    WideArrow,     // =>
    // Operators
    Address,       // @
    Cash,          // $
    Pound,         // #
    Bang,          // !
    Question,      // ?
    RangeExc,      // ..
    RangeInc,      // ..=
    ForwardApp,    // <|
    ReverseApp,    // |>
    Concat,        // <>
    // Arithmetic
    Plus,          // +
    Minus,         // -
    Asterisk,      // *
    Slash,         // /
    Percent,       // %
    Increment,     // ++
    Decrement,     // --
    Square,        // **
    // Bitwise
    Ampersand,     // &
    Pipe,          // |
    Caret,         // ^
    Tilde,         // ~
    Lshift,        // <<
    Rshift,        // >>
    // Comparators
    Lesser,        // <
    LesserEq,      // <=
    Greater,       // >
    GreaterEq,     // >=
    Equal,         // ==
    NotEqual,      // !=
    // Miscelaneous
    Newline,       // \n
    Illegal,
    Eof,

    // Tries to create a Kind from a byte
    pub fn from_byte(byte: u8) Kind {
        return switch(byte) {
            // Assignment
            '='    => .Assign,
            // Punctuation
            '.'    => .Dot,
            ','    => .Comma,
            '('    => .Lparen,
            ')'    => .Rparen,
            '['    => .Lbracket,
            ']'    => .Rbracket,
            '{'    => .Lsquirly,
            '}'    => .Rsquirly,
            '\''   => .Quote,
            '"'    => .Dblquote,
            '`'    => .Backtick,
            '\\'   => .Backslash,
            ':'    => .Colon,
            ';'    => .Semicolon,
            // Operators
            '@'    => .Address,
            '$'    => .Cash,
            '#'    => .Pound,
            '!'    => .Bang,
            '?'    => .Question,
            // Arithmetic
            '+'    => .Plus,
            '-'    => .Minus,
            '*'    => .Asterisk,
            '/'    => .Slash,
            '%'    => .Percent,
            // Bitwise
            '&'    => .Ampersand,
            '|'    => .Pipe,
            '^'    => .Caret,
            '~'    => .Tilde,
            // Comparators
            '<'    => .Lesser,
            '>'    => .Greater,
            // Miscelaneous
            '\n'   => .Newline,
            '\x00' => .Eof,
            else   => .Illegal
        };
    }

    // Converts a Kind into a string slice
    pub fn to_str(self: *const Kind, allocator: std.mem.Allocator) ![]const u8 {
        return switch(self.*) {
            // Kinds with associated values
            .Identifier   => |id| id,
            .String       => |st| st,
            .Character    => |ch| try self.char_to_string(ch, allocator),
            .Integer      => |in| in,
            .Float        => |fl| fl,
            .Keyword      => |ke| ke.to_str(),
            .Mode         => |mo| mo.to_str(),
            // Assignment
            .Assign       => "=",
            .AssignExp    => ":=",
            // Punctuation
            .Dot          => ".",
            .Comma        => ",",
            .Lparen       => "(",
            .Rparen       => ")",
            .Lbracket     => "[",
            .Rbracket     => "]",
            .Lsquirly     => "{",
            .Rsquirly     => "}",
            .Quote        => "'",
            .Dblquote     => "\"",
            .Backtick     => "`",
            .Backslash    => "\\",
            .Colon        => ":",
            .Semicolon    => ";",
            .Arrow        => "->",
            .WideArrow    => "=>",
            // Operators
            .Address      => "@",
            .Cash         => "$",
            .Pound        => "#",
            .Bang         => "!",
            .Question     => "?",
            .RangeExc     => "..",
            .RangeInc     => "..=",
            .ForwardApp   => "<|",
            .ReverseApp   => "|>",
            .Concat       => "<>",
            // Arithmetic
            .Plus         => "+",
            .Minus        => "-",
            .Asterisk     => "*",
            .Slash        => "/",
            .Percent      => "%",
            .Increment    => "++",
            .Decrement    => "--",
            .Square       => "**",
            // Bitwise
            .Ampersand    => "&",
            .Pipe         => "|",
            .Caret        => "^",
            .Tilde        => "~",
            .Lshift       => "<<",
            .Rshift       => ">>",
            // Comparators
            .Lesser       => "<",
            .LesserEq     => "<=",
            .Greater      => ">",
            .GreaterEq    => ">=",
            .Equal        => "==",
            .NotEqual     => "!=",
            // Miscelaneous
            .Newline      => "\n",
            .Illegal      => "ILLEGAL",
            .Eof          => "EOF"
        };
    }

    fn char_to_string(_: *const Kind, ch: u8, allocator: std.mem.Allocator) ![]const u8 {
        var str = try allocator.alloc(u8, 1); 
        str[0] = ch;
        return str[0..];
    }

    /// Tries to create a keyword Kind from a string slice
    pub fn try_keyword(slice: []const u8) ?Kind {
        const keyword = keywords.get(slice) orelse return null;
        return .{.Keyword = keyword};
    }

    /// Tries to create a mode Kind from a string slice
    pub fn try_mode(slice: []const u8) ?Kind {
        const mode = modes.get(slice) orelse return null;
        return .{.Mode = mode};
    }
};

/// Represents the official keywords of Ruka, and the reserved
const Keyword = enum {
    Const,
    Let,
    Pub,
    Return,
    Do,
    End,
    Record,
    Variant,
    Interface,
    Module,
    Defer,
    True,
    False,
    For,
    While,
    Break,
    Continue,
    Match,
    If,
    Else,
    And,
    Or,
    Not,
    Inline,
    Test,
    Fn,
    In,
    // Reserved
    Private,
    Derive,
    Static,
    Macro,
    From,
    Impl,
    When,
    Any,
    Use,
    As,

    /// Converts a Keyword into a string slice
    pub fn to_str(self: *const Keyword) []const u8 {
        for (keywords.kvs) |pair| {
            if (pair.value == self.*) {
                return pair.key;
            }
        }
        unreachable;
    }
};

// Map representing Keywords and their string representation
const keywords = std.ComptimeStringMap(Keyword, .{
    .{"const", .Const},
    .{"let", .Let},
    .{"pub", .Pub},
    .{"return", .Return},
    .{"do", .Do},
    .{"end", .End},
    .{"record", .Record},
    .{"variant", .Variant},
    .{"interface", .Interface},
    .{"module", .Module},
    .{"defer", .Defer},
    .{"true", .True},
    .{"false", .False},
    .{"for", .For},
    .{"while", .While},
    .{"break", .Break},
    .{"continue", .Continue},
    .{"match", .Match},
    .{"if", .If},
    .{"else", .Else},
    .{"and", .And},
    .{"or", .Or},
    .{"not", .Not},
    .{"inline", .Inline},
    .{"test", .Test},
    .{"fn", .Fn},
    .{"in", .In},
    // Reserved
    .{"private", .Private},
    .{"derive", .Derive},
    .{"static", .Static},
    .{"macro", .Macro},
    .{"from", .From},
    .{"impl", .Impl},
    .{"when", .When},
    .{"any", .Any},
    .{"use", .Use},
    .{"as", .As}
});

// Compile time assert no missing or extra entries in keywords
comptime {
    //var fields: [@typeInfo(Keyword).Enum.fields.len]std.builtin.Type.EnumField = undefined;
    //@memcpy(&fields, @typeInfo(Keyword).Enum.fields);
    //
    //const SortContext = struct {
    //    fields: []std.builtin.Type.EnumField,

    //    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
    //        return ctx.fields[a].name.len < ctx.fields[b].name.len;
    //    }

    //    pub fn swap(ctx: @This(), a: usize, b: usize) void {
    //        return std.mem.swap(std.builtin.Type.EnumField, &ctx.fields[a], &ctx.fields[b]);
    //    }
    //};
    //std.mem.sortUnstableContext(0, fields.len, SortContext{.fields = &fields});

    const fields = @typeInfo(Keyword).Enum.fields;
    if (fields.len != keywords.kvs.len) {
        var buf: [100]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf,
            "Keywords map has an incorrect number of elements, expected: {}, got: {}",
            .{fields.len, keywords.kvs.len}
            ) catch unreachable;

        @compileError(msg);
    }

    //for (fields, keywords.kvs) |field, pair| {
    //    if (!std.mem.eql(u8, field.name, @tagName(pair.value))) {
    //        var buf: [100]u8 = undefined;
    //        const msg = std.fmt.bufPrint(&buf,
    //            "Keywords map has an incorrect pair, expected: {s}, got: {s}",
    //            .{field.name, @tagName(pair.value)}
    //            ) catch unreachable;

    //        @compileError(msg);
    //    }
    //}
}

/// Represent various parameter modes
const Mode = enum {
    Comptime,
    Loc,
    Mov,
    Mut,

    /// Converts a Mode into a string slice
    pub fn to_str(self: *const Mode) []const u8 {
        for (modes.kvs) |pair| {
            if (pair.value == self.*) {
                return pair.key;
            }
        }
        unreachable;
    }
};

// Map representing Keywords and their string representation
const modes = std.ComptimeStringMap(Mode, .{
    .{"comptime", .Comptime},
    .{"loc", .Loc},
    .{"mov", .Mov},
    .{"mut", .Mut}
});

// Compile time assert no missing or extra entries in modes
comptime {
    //var fields: [@typeInfo(Mode).Enum.fields.len]std.builtin.Type.EnumField = undefined;
    //@memcpy(&fields, @typeInfo(Mode).Enum.fields);
    //
    //const SortContext = struct {
    //    fields: []std.builtin.Type.EnumField,

    //    pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
    //        return ctx.fields[a].name.len < ctx.fields[b].name.len;
    //    }

    //    pub fn swap(ctx: @This(), a: usize, b: usize) void {
    //        return std.mem.swap(std.builtin.Type.EnumField, &ctx.fields[a], &ctx.fields[b]);
    //    }
    //};
    //std.mem.sortUnstableContext(0, fields.len, SortContext{.fields = &fields});

    const fields = @typeInfo(Mode).Enum.fields;
    if (fields.len != modes.kvs.len) {
        var buf: [100]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf,
            "Modes map has an incorrect number of elements, expected: {}, got: {}",
            .{fields.len, modes.kvs.len}
            ) catch unreachable;

        @compileError(msg);
    }

    //for (fields, modes.kvs) |field, pair| {
    //    if (!std.mem.eql(u8, field.name, @tagName(pair.value))) {
    //        var buf: [100]u8 = undefined;
    //        const msg = std.fmt.bufPrint(&buf,
    //            "Modes map has an incorrect pair, expected: {s}, got: {s}",
    //            .{field.name, @tagName(pair.value)}
    //            ) catch unreachable;

    //        @compileError(msg);
    //    }
    //}
}

test "mode comparision" {
    const testing = std.testing;

    const mode: Kind = .{.Mode = .Mut};
    const mode2 = Kind.try_mode("mut").?;

    try testing.expect(mode.Mode == mode2.Mode);
}