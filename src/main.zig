const std = @import("std");
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    const source =
        \\ if (x > 10) {
        \\    if (y == 5) {
        \\        x = 0;
        \\    } else {
        \\        x = 1;
        \\    }
        \\} else {
        \\    x = 2;
        \\}
    ;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var parser = Parser.init(source, arena.allocator());
    const statement = try parser.parseStatement();
    switch (statement) {
        .block => |block| {
            std.debug.print("Parsed block with {d} statements\n", .{
                block.statements.len,
            });
        },
        .if_statement => |if_stmt| {
            std.debug.print("Parsed if statement , {} \n", .{if_stmt.condition.*});

            if (if_stmt.else_branch != null) {
                std.debug.print("Has else branch\n", .{});
            }
        },
        .expression => |expression| {
            switch (expression.*) {
                .number => |value| {
                    std.debug.print("Parsed number: {d}\n", .{value});
                },
                .identifier => |name| {
                    std.debug.print("Parsed identifier: {s}\n", .{name});
                },
                .unary => |unary| {
                    std.debug.print("Parsed unary expression: {s}\n", .{
                        @tagName(unary.operator),
                    });
                },
                .binary => |binary| {
                    std.debug.print("Parsed binary expression: {s}\n", .{
                        @tagName(binary.operator),
                    });
                },
                .assignment => |assignment| {
                    std.debug.print("Parsed assignment: {s} = ...\n", .{assignment.name});
                },
                else => {
                    std.debug.print("Parsed other expression\n", .{});
                },
            }
        },
        .declaration => |declaration| {
            std.debug.print(
                "Parsed declaration: {s}, type: {s}, mutable: {}\n",
                .{
                    declaration.name,
                    @tagName(declaration.type),
                    declaration.mutable,
                },
            );
        },
    }
}
