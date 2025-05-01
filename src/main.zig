const rl = @import("raylib");
const gameLogic = @import("game.zig");

pub fn main() anyerror!void {
    rl.traceLog(rl.TraceLogLevel.info, "Initializing Game!", .{});
    // Initialization
    //--------------------------------------------------------------------------------------
    gameLogic.startGame();
    defer rl.closeWindow(); // Close window and OpenGL context
    while (gameLogic.updateFrame()) {}
}
