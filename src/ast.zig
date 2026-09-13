pub const Type = enum { int, bool, string };
pub const BinaryOperator = enum {
    add,
    subtract,
    multiply,
    divide,
    equal,
    not_equal,
    less,
    less_equal,
    greater,
    greater_equal,
};
pub const UnaryOperator = enum {
    negate,
    not,
};
pub const Expression = union(enum) {
    number: i64,
    boolean: bool,
    string: []const u8,
    identifier: []const u8,
    binary: struct {
        left: *Expression,
        operator: BinaryOperator,
        right: *Expression,
    },
    unary: struct {
        operator: UnaryOperator,
        operand: *Expression,
    },
    assignment: struct {
        name: []const u8,
        value: *Expression,
    },
};
pub const Declaration = struct {
    mutable: bool,
    type: Type,
    name: []const u8,
    value: *Expression,
};
pub const Statement = union(enum) {
    declaration: Declaration,
    expression: *Expression,
    block: struct {
        statements: []*Statement,
    },
    if_statement: struct {
        condition: *Expression,
        then_branch: *Statement,
        else_branch: ?*Statement,
    },
    while_statement: struct {
        condition: *Expression,
        body: *Statement,
    },
};
