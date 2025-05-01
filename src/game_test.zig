const std = @import("std");
const expect = std.testing.expect;
const Game = @import("game.zig");

test "[Game] start game test" {
    Game.isTesting = true;
    Game.startGame();
    try expect(Game.game.state == Game.GameStateType.StateStartMenu);
}

test "[Game] update frame test" {
    Game.isTesting = true;
    Game.startGame();
    // Game.updateFrame();
    try expect(Game.game.state == Game.GameStateType.StateStartMenu);
}
