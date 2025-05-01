const std = @import("std");

pub const game_test = @import("game_test.zig");
// etc

test {
    std.testing.refAllDecls(@This());
}
