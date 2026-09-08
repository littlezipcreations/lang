const std = @import("std");

pub const TokenType = enum {
    semicolon,
    colon,
    comma,
    quote,
    dobquote,
    exclam_mark,
    plus,
    minus,
    asterisk,
    slash,
    lroundbracket,
    rroundbracket,
    lcurlybracket,
    rcurlybracket,
    lsquarebracket,
    rsquarebracket,
    ltrianglebracket,
    rtrianglebracket,
    lessoreq,
    moreoreq,
    noteq,
    number,
    identifier,
    keyword_if,
    keyword_else,
    keyword_while,
    keyword_return,
    keyword_fn,
    keyword_struct,
    keyword_class,
    keyword_const,
    keyword_mut,
    keyword_int,
    keyword_bool,
    keyword_string,
    true,
    false,
    equal,
    dobequal,
    eof,
    invalid,
};

pub const Token = struct {
    tag: TokenType,
    loc: []const u8,
    start: usize,
    end: usize,
};

pub const Lexer = struct {
    buffer: []const u8,
    index: usize,

    pub fn init(source_code: []const u8) Lexer {
        return Lexer{
            .buffer = source_code,
            .index = 0,
        };
    }

    fn advance(self: *Lexer) ?u8 {
        if (self.index >= self.buffer.len) {
            return null;
        }

        const char = self.buffer[self.index];
        self.index += 1;
        return char;
    }

    fn peek(self: *Lexer) ?u8 {
        if (self.index >= self.buffer.len) {
            return null;
        }

        return self.buffer[self.index];
    }

    fn skipWS(self: *Lexer) void {
        while (self.peek()) |char| {
            switch (char) {
                ' ', '\t', '\n', '\r' => {
                    _ = self.advance();
                },
                else => break,
            }
        }
    }

    pub fn next(self: *Lexer) Token {
        self.skipWS();

        const start = self.index;

        const char = self.advance() orelse {
            return Token{
                .tag = .eof,
                .loc = self.buffer[start..start],
                .start = start,
                .end = start,
            };
        };

        // Numbers
        if (std.ascii.isDigit(char)) {
            while (self.peek()) |next_char| {
                if (!std.ascii.isDigit(next_char)) {
                    break;
                }

                _ = self.advance();
            }

            return Token{
                .tag = .number,
                .loc = self.buffer[start..self.index],
                .start = start,
                .end = self.index,
            };
        }

        // Identifiers and keywords
        if (std.ascii.isAlphabetic(char) or char == '_') {
            while (self.peek()) |next_char| {
                if (!std.ascii.isAlphanumeric(next_char) and next_char != '_') {
                    break;
                }

                _ = self.advance();
            }

            const word_text = self.buffer[start..self.index];

            if (std.mem.eql(u8, word_text, "if")) {
                return Token{ .tag = .keyword_if, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "else")) {
                return Token{ .tag = .keyword_else, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "while")) {
                return Token{ .tag = .keyword_while, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "return")) {
                return Token{ .tag = .keyword_return, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "fn")) {
                return Token{ .tag = .keyword_fn, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "struct")) {
                return Token{ .tag = .keyword_struct, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "class")) {
                return Token{ .tag = .keyword_class, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "const")) {
                return Token{ .tag = .keyword_const, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "mut")) {
                return Token{ .tag = .keyword_mut, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "true")) {
                return Token{ .tag = .true, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "false")) {
                return Token{ .tag = .false, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "int")) {
                return Token{ .tag = .keyword_int, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "bool")) {
                return Token{ .tag = .keyword_bool, .loc = word_text, .start = start, .end = self.index };
            } else if (std.mem.eql(u8, word_text, "string")) {
                return Token{ .tag = .keyword_string, .loc = word_text, .start = start, .end = self.index };
            }

            return Token{
                .tag = .identifier,
                .loc = word_text,
                .start = start,
                .end = self.index,
            };
        }

        switch (char) {
            ';' => {
                return Token{ .tag = .semicolon, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            ':' => {
                return Token{ .tag = .colon, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            ',' => {
                return Token{ .tag = .comma, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '"' => {
                return Token{ .tag = .quote, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '\'' => {
                return Token{ .tag = .dobquote, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '+' => {
                return Token{ .tag = .plus, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '-' => {
                return Token{ .tag = .minus, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '*' => {
                return Token{ .tag = .asterisk, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '/' => {
                return Token{ .tag = .slash, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '(' => {
                return Token{ .tag = .lroundbracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            ')' => {
                return Token{ .tag = .rroundbracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '[' => {
                return Token{ .tag = .lsquarebracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            ']' => {
                return Token{ .tag = .rsquarebracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '{' => {
                return Token{ .tag = .lcurlybracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '}' => {
                return Token{ .tag = .rcurlybracket, .loc = self.buffer[start..self.index], .start = start, .end = self.index };
            },

            '<' => {
                if (self.peek()) |next_char| {
                    if (next_char == '=') {
                        _ = self.advance();

                        return Token{
                            .tag = .lessoreq,
                            .loc = self.buffer[start..self.index],
                            .start = start,
                            .end = self.index,
                        };
                    }
                }

                return Token{
                    .tag = .ltrianglebracket,
                    .loc = self.buffer[start..self.index],
                    .start = start,
                    .end = self.index,
                };
            },

            '>' => {
                if (self.peek()) |next_char| {
                    if (next_char == '=') {
                        _ = self.advance();

                        return Token{
                            .tag = .moreoreq,
                            .loc = self.buffer[start..self.index],
                            .start = start,
                            .end = self.index,
                        };
                    }
                }

                return Token{
                    .tag = .rtrianglebracket,
                    .loc = self.buffer[start..self.index],
                    .start = start,
                    .end = self.index,
                };
            },

            '!' => {
                if (self.peek()) |next_char| {
                    if (next_char == '=') {
                        _ = self.advance();

                        return Token{
                            .tag = .noteq,
                            .loc = self.buffer[start..self.index],
                            .start = start,
                            .end = self.index,
                        };
                    }
                }

                return Token{
                    .tag = .exclam_mark,
                    .loc = self.buffer[start..self.index],
                    .start = start,
                    .end = self.index,
                };
            },

            '=' => {
                if (self.peek()) |next_char| {
                    if (next_char == '=') {
                        _ = self.advance();

                        return Token{
                            .tag = .dobequal,
                            .loc = self.buffer[start..self.index],
                            .start = start,
                            .end = self.index,
                        };
                    }
                }

                return Token{
                    .tag = .equal,
                    .loc = self.buffer[start..self.index],
                    .start = start,
                    .end = self.index,
                };
            },

            else => {
                return Token{
                    .tag = .invalid,
                    .loc = self.buffer[start..self.index],
                    .start = start,
                    .end = self.index,
                };
            },
        }
    }
};

pub fn main() !void {
    const source =
        \\if (x == 42) {
        \\mut int_value = 123;
        \\value != 456;
        \\value <= 100;
        \\value >= 10;
        \\x + y - z * 2 / 3;
        \\function_name = "hello";
        \\const thing = true;
        \\thing = false;
        \\return [1, 2, 3];
        \\} else {
        \\while (counter < 10) {
        \\    counter = counter + 1;
        \\}
        \\}
    ;

    var my_lexer = Lexer.init(source);

    std.debug.print("Lexing:\n{s}\n\n", .{source});

    while (true) {
        const token = my_lexer.next();

        std.debug.print(
            "Found Token: {s} -> \"{s}\" [{d}..{d}]\n",
            .{
                @tagName(token.tag),
                token.loc,
                token.start,
                token.end,
            },
        );

        if (token.tag == .eof) {
            break;
        }
    }
}
