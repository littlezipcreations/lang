const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;
const ast = @import("ast.zig");
const ParseError = error{ ExpectedExpression, ExpectedSemicolon, ExpectedOpeningBracket, ExpectedClosingBracket, OutOfMemory, Overflow, InvalidCharacter, ExpectedIdentifier, ExpectedEqual, ExpectedType, UnterminatedString, ExpectedOpeningBrace, ExpectedClosingBrace, ExpectedIf };
pub const Parser = struct {
    lexer: Lexer,
    current: Token,
    allocator: std.mem.Allocator,

    pub fn init(source: []const u8, allocator: std.mem.Allocator) Parser {
        var parser = Parser{
            .lexer = Lexer.init(source),
            .current = undefined,
            .allocator = allocator,
        };

        parser.advance();
        return parser;
    }

    fn advance(self: *Parser) void {
        self.current = self.lexer.next();
    }
    fn parsePrimary(self: *Parser) !*ast.Expression {
        const token = self.current;
        const node = try self.allocator.create(ast.Expression);
        switch (token.tag) {
            .number => {
                const value = try std.fmt.parseInt(i64, token.loc, 10);
                node.* = .{
                    .number = value,
                };
                self.advance();
                return node;
            },
            .identifier => {
                node.* = .{
                    .identifier = token.loc,
                };
                self.advance();
                return node;
            },
            .lroundbracket => {
                self.advance();
                const expression = try self.parseAddition();
                if (self.current.tag != .rroundbracket) {
                    self.allocator.destroy(node);
                    return ParseError.ExpectedClosingBracket;
                }
                self.advance();
                return expression;
            },
            .quote => {
                self.advance();
                const start = self.current.start;
                while (self.current.tag != .quote) {
                    if (self.current.tag == .eof) {
                        return ParseError.UnterminatedString;
                    }
                    self.advance();
                }
                const end = self.current.start;
                node.* = .{
                    .string = self.lexer.buffer[start..end],
                };
                self.advance();
                return node;
            },
            .dobquote => {
                self.advance();
                const start = self.current.start;
                while (self.current.tag != .dobquote) {
                    if (self.current.tag == .eof) {
                        return ParseError.UnterminatedString;
                    }
                    self.advance();
                }
                const end = self.current.start;
                node.* = .{
                    .string = self.lexer.buffer[start..end],
                };
                self.advance();
                return node;
            },
            .minus => {
                self.advance();

                const operand = try self.parsePrimary();

                node.* = .{
                    .unary = .{
                        .operator = .negate,
                        .operand = operand,
                    },
                };

                return node;
            },
            .exclam_mark => {
                self.advance();
                const operand = try self.parsePrimary();
                node.* = .{
                    .unary = .{
                        .operator = .not,
                        .operand = operand,
                    },
                };
                return node;
            },
            .true => {
                node.* = .{
                    .boolean = true,
                };
                self.advance();
                return node;
            },
            .false => {
                node.* = .{
                    .boolean = false,
                };
                self.advance();
                return node;
            },
            else => {
                self.allocator.destroy(node);
                return ParseError.ExpectedExpression;
            },
        }
    }
    fn parseBlock(self: *Parser) ParseError!ast.Statement {
        if (self.current.tag != .lcurlybracket) {
            return ParseError.ExpectedOpeningBrace;
        }
        self.advance();
        var statements = std.ArrayList(*ast.Statement).empty;
        while (self.current.tag != .rcurlybracket) {
            if (self.current.tag == .eof) {
                return ParseError.ExpectedClosingBrace;
            }
            const statement = try self.allocator.create(ast.Statement);
            statement.* = try self.parseStatement();
            try statements.append(self.allocator, statement);
        }
        self.advance();
        return .{ .block = .{
            .statements = try statements.toOwnedSlice(self.allocator),
        } };
    }
    fn parseIfStatement(self: *Parser) ParseError!ast.Statement {
        if (self.current.tag != .keyword_if) {
            return ParseError.ExpectedIf;
        }

        self.advance();

        if (self.current.tag != .lroundbracket) {
            return ParseError.ExpectedOpeningBracket;
        }

        self.advance();

        const condition = try self.parseAssignment();

        if (self.current.tag != .rroundbracket) {
            return ParseError.ExpectedClosingBracket;
        }

        self.advance();

        const then_statement = try self.allocator.create(ast.Statement);
        then_statement.* = try self.parseBlock();

        var else_statement: ?*ast.Statement = null;

        if (self.current.tag == .keyword_else) {
            self.advance();

            const statement = try self.allocator.create(ast.Statement);
            statement.* = try self.parseBlock();

            else_statement = statement;
        }

        return .{
            .if_statement = .{
                .condition = condition,
                .then_branch = then_statement,
                .else_branch = else_statement,
            },
        };
    }
    fn parseExpressionStatement(self: *Parser) ParseError!ast.Statement {
        const expression = try self.parseAssignment();
        if (self.current.tag != .semicolon) {
            return ParseError.ExpectedSemicolon;
        }
        self.advance();
        return .{ .expression = expression };
    }
    fn parseMultiplication(self: *Parser) ParseError!*ast.Expression {
        var left = try self.parsePrimary();

        while (self.current.tag == .asterisk or self.current.tag == .slash) {
            const operator: ast.BinaryOperator = switch (self.current.tag) {
                .asterisk => .multiply,
                .slash => .divide,
                else => unreachable,
            };

            self.advance();

            const right = try self.parsePrimary();

            const node = try self.allocator.create(ast.Expression);

            node.* = .{
                .binary = .{
                    .left = left,
                    .operator = operator,
                    .right = right,
                },
            };

            left = node;
        }

        return left;
    }
    fn parseAddition(self: *Parser) ParseError!*ast.Expression {
        var left = try self.parseMultiplication();

        while (self.current.tag == .plus or self.current.tag == .minus) {
            const operator: ast.BinaryOperator = switch (self.current.tag) {
                .plus => .add,
                .minus => .subtract,
                else => unreachable,
            };

            self.advance();

            const right = try self.parseMultiplication();

            const node = try self.allocator.create(ast.Expression);

            node.* = .{
                .binary = .{
                    .left = left,
                    .operator = operator,
                    .right = right,
                },
            };

            left = node;
        }

        return left;
    }
    fn parseAssignment(self: *Parser) ParseError!*ast.Expression {
        const left = try self.parseEquality();

        if (self.current.tag != .equal) {
            return left;
        }

        if (left.* != .identifier) {
            return error.ExpectedIdentifier;
        }

        const name = left.identifier;

        self.advance();

        const value = try self.parseAssignment();

        const node = try self.allocator.create(ast.Expression);

        node.* = .{
            .assignment = .{
                .name = name,
                .value = value,
            },
        };

        return node;
    }
    fn parseEquality(self: *Parser) ParseError!*ast.Expression {
        var left = try self.parseComparison();
        while (self.current.tag == .dobequal or self.current.tag == .noteq) {
            const operator: ast.BinaryOperator = switch (self.current.tag) {
                .dobequal => .equal,
                .noteq => .not_equal,
                else => unreachable,
            };
            self.advance();
            const right = try self.parseComparison();
            const node = try self.allocator.create(ast.Expression);
            node.* = .{
                .binary = .{
                    .left = left,
                    .operator = operator,
                    .right = right,
                },
            };
            left = node;
        }
        return left;
    }
    fn parseComparison(self: *Parser) ParseError!*ast.Expression {
        var left = try self.parseAddition();
        while (self.current.tag == .ltrianglebracket or self.current.tag == .lessoreq or self.current.tag == .rtrianglebracket or self.current.tag == .moreoreq) {
            const operator: ast.BinaryOperator = switch (self.current.tag) {
                .ltrianglebracket => .less,
                .lessoreq => .less_equal,
                .rtrianglebracket => .greater,
                .moreoreq => .greater_equal,
                else => unreachable,
            };

            self.advance();

            const right = try self.parseAddition();

            const node = try self.allocator.create(ast.Expression);

            node.* = .{
                .binary = .{
                    .left = left,
                    .operator = operator,
                    .right = right,
                },
            };

            left = node;
        }
        return left;
    }
    pub fn parseStatement(self: *Parser) ParseError!ast.Statement {
        if (self.current.tag == .keyword_if) {
            return self.parseIfStatement();
        }
        if (self.current.tag == .keyword_mut or
            self.current.tag == .keyword_int or
            self.current.tag == .keyword_bool or
            self.current.tag == .keyword_string)
        {
            return self.parseDeclaration();
        }
        if (self.current.tag == .lcurlybracket) {
            return self.parseBlock();
        }

        return self.parseExpressionStatement();
    }
    fn parseDeclaration(self: *Parser) ParseError!ast.Statement {
        var mutable = false;
        if (self.current.tag == .keyword_mut) {
            mutable = true;
            self.advance();
        }
        const vartype: ast.Type = switch (self.current.tag) {
            .keyword_int => .int,
            .keyword_bool => .bool,
            .keyword_string => .string,
            else => return error.ExpectedIdentifier,
        };
        self.advance();
        if (self.current.tag != .identifier) {
            return error.ExpectedIdentifier;
        }
        const name = self.current.loc;
        self.advance();
        if (self.current.tag != .equal) {
            return error.ExpectedEqual;
        }
        self.advance();
        const value = try self.parseEquality();
        if (self.current.tag != .semicolon) {
            return error.ExpectedSemicolon;
        }
        self.advance();
        return .{
            .declaration = .{
                .name = name,
                .mutable = mutable,
                .type = vartype,
                .value = value,
            },
        };
    }
};
