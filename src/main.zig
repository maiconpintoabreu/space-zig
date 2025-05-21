const rl = @import("raylib");
const gameLogic = @import("game.zig");

pub fn main() anyerror!void {
    rl.traceLog(rl.TraceLogLevel.info, "Initializing Game!", .{});
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60);
    gameLogic.startGame();

    while (gameLogic.updateFrame()) {}
}
