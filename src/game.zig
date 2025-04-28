const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Color = rl.Color;

const PLAYER_SPEED: f32 = 100.0;
const PLAYER_ROTATION_SPEED: f32 = 100.0;
const SHIP_HALF_HEIGHT: f32 = 5.0 / 0.363970;
const PHYSICS_TIME: f32 = 0.02;
const FONT_SIZE: i8 = 20;
const DEG2RAD = 3.14159265358979323846 / 100.0;

const Player = struct {
    position: rl.Vector2 = .{ .x = 0, .y = 0 },
    topPoint: rl.Vector2 = .{ .x = 0, .y = 0 },
    leftPoint: rl.Vector2 = .{ .x = 0, .y = 0 },
    rightPoint: rl.Vector2 = .{ .x = 0, .y = 0 },
    speed: rl.Vector2 = .{ .x = 0, .y = 0 },
    rotation: f32 = 0,
    acceleration: f32 = 0,
    isTurnLeft: bool = false,
    isTurnRight: bool = false,
    isAccelerating: bool = false,
    isBreaking: bool = false,
};

const GameStateType = enum(u2) {
    StateInGame,
    StateStartMenu,
    StateGameOver,
};

const Game = struct {
    width: i32 = 0,
    height: i32 = 0,
    fwidth: f32 = 0,
    fheight: f32 = 0,
    halfWidth: f32 = 0.0,
    halfHeight: f32 = 0.0,
    frameTimeAccumulator: f32 = 0,
    isPlayerRotationChange: bool = false,
    currentScore: f32 = 0,
    highestScore: f32 = 0,
    state: GameStateType = GameStateType.StateStartMenu,
    player: Player = .{},
};

var game: Game = .{};
const menu_size_width: f32 = 200.0;
const item_menu_size_height: f32 = 50.0;
const acceleration: f32 = PLAYER_SPEED * PHYSICS_TIME;
var exitMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
var startMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
var restartMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };

pub fn startGame() void {
    game.width = 640;
    game.height = 360;

    rl.initWindow(game.width, game.height, "Space Zig");

    PlaceUIButtons();
    ResetPlayer();

    game.state = GameStateType.StateStartMenu;
}

fn MenuButtom(buttom: rl.Rectangle, buttom_text: [:0]const u8) bool {
    if (rl.isMouseButtonDown(rl.MouseButton.left) and rl.checkCollisionPointRec(rl.getMousePosition(), buttom)) {
        return true;
    }
    rl.drawRectangleRec(buttom, Color.gray);

    rl.drawText(buttom_text, @as(i32, @intFromFloat(buttom.x)) + 20, @as(i32, @intFromFloat(buttom.y + buttom.height / 2)) - 10, 20, Color.white);
    return false;
}

fn PlaceUIButtons() void {
    game.width = rl.getScreenWidth();
    game.height = rl.getScreenHeight();
    game.fwidth = @as(f32, @floatFromInt(game.width));
    game.fheight = @as(f32, @floatFromInt(game.height));
    game.halfWidth = game.fwidth / 2.0;
    game.halfHeight = game.fheight / 2.0;
    // Add start button
    startMenuRec.x = (game.fwidth / 2) - menu_size_width / 2;
    startMenuRec.y = (game.fheight / 2) - item_menu_size_height / 1.5;
    startMenuRec.width = menu_size_width;
    startMenuRec.height = item_menu_size_height;
    // Add restart button
    restartMenuRec = startMenuRec;
    // Add exit button
    exitMenuRec.x = (game.fwidth / 2) - menu_size_width / 2;
    exitMenuRec.y = (game.fheight / 2) + item_menu_size_height / 1.5;
    exitMenuRec.width = menu_size_width;
    exitMenuRec.height = item_menu_size_height;
}

fn ResetPlayer() void {
    game.player.position.x = game.halfWidth;
    game.player.position.y = game.halfHeight - (SHIP_HALF_HEIGHT / 2.0);
    game.player.speed.x = 0.0;
    game.player.speed.y = 0.0;
    game.player.acceleration = 0.0;
    game.player.isAccelerating = false;
    game.player.isBreaking = false;
    game.player.isTurnLeft = false;
    game.player.isTurnRight = false;
    game.frameTimeAccumulator = 0.0;

    game.isPlayerRotationChange = false;
}

pub fn updateFrame() void {
    if (rl.isWindowResized()) {
        PlaceUIButtons();
    }
    // Tick
    if (game.state == GameStateType.StateInGame) {
        // Input
        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            game.player.isTurnLeft = true;
            game.isPlayerRotationChange = true;
        } else {
            game.player.isTurnLeft = false;
        }
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            game.player.isTurnRight = true;
            game.isPlayerRotationChange = true;
        } else {
            game.player.isTurnRight = false;
        }

        if (rl.isKeyDown(rl.KeyboardKey.up)) {
            game.player.isAccelerating = true;
        } else {
            game.player.isAccelerating = false;
        }

        if (rl.isKeyDown(rl.KeyboardKey.down)) {
            game.player.isBreaking = true;
        } else {
            game.player.isBreaking = false;
        }

        // Physics
        game.frameTimeAccumulator += rl.getFrameTime();
        if (game.frameTimeAccumulator > PHYSICS_TIME) {
            game.frameTimeAccumulator = 0.0;

            if (game.player.isTurnLeft) {
                game.player.rotation -= PLAYER_ROTATION_SPEED * PHYSICS_TIME;
            } else if (game.player.isTurnRight) {
                game.player.rotation += PLAYER_ROTATION_SPEED * PHYSICS_TIME;
            }

            // if (game.isPlayerRotationChange) {
            //     if (game.player.rotation > 180.0) {
            //         game.player.rotation -= 360.0;
            //     }
            //     if (game.player.rotation < -180.0) {
            //         game.player.rotation += 360.0;
            //     }
            // }
            if (game.player.isAccelerating) {
                if (game.player.acceleration < PLAYER_SPEED) {
                    game.player.acceleration += acceleration;
                }
            } else if (game.player.acceleration > 0.0) {
                game.player.acceleration -= acceleration / 2.0;
            } else if (game.player.acceleration < 0.0) {
                game.player.acceleration = 0.0;
            }
            if (game.player.isBreaking) {
                if (game.player.acceleration > 0.0) {
                    game.player.acceleration -= acceleration;
                } else if (game.player.acceleration < 0.0) {
                    game.player.acceleration = 0.0;
                }
            }

            const direction: rl.Vector2 = .{ .x = math.sin(game.player.rotation * DEG2RAD), .y = -math.cos(game.player.rotation * DEG2RAD) };
            const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
            game.player.speed = rl.Vector2.scale(norm_vector, game.player.acceleration * PHYSICS_TIME);
            game.player.position = rl.Vector2.add(game.player.position, game.player.speed);
            // Update Triangle Rotation
            if (rl.Vector2.length(game.player.speed) > 0.0) {
                if (game.player.position.x > game.fwidth + SHIP_HALF_HEIGHT) {
                    game.player.position.x = -SHIP_HALF_HEIGHT;
                } else if (game.player.position.x < -SHIP_HALF_HEIGHT) {
                    game.player.position.x = game.fwidth + SHIP_HALF_HEIGHT;
                }

                if (game.player.position.y > game.fheight + SHIP_HALF_HEIGHT) {
                    game.player.position.y = -SHIP_HALF_HEIGHT;
                } else if (game.player.position.y < -SHIP_HALF_HEIGHT) {
                    game.player.position.y = game.fheight + SHIP_HALF_HEIGHT;
                }
            }
        }
    }

    // Draw
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(Color.gray);
    const fps = rl.getFPS();
    rl.drawText(rl.textFormat("FPS: %03i", .{fps}), game.width - 100, 12, FONT_SIZE, Color.white);
    switch (game.state) {
        GameStateType.StateInGame => {
            rl.drawText(rl.textFormat("Speed: %03.0f", .{game.player.acceleration}), 20, 12, FONT_SIZE, Color.white);
            // Draw In Game UI

            const cosf: f32 = math.cos(game.player.rotation * DEG2RAD);
            const sinf: f32 = math.sin(game.player.rotation * DEG2RAD);

            game.player.topPoint.x = game.player.position.x + sinf * SHIP_HALF_HEIGHT;
            game.player.topPoint.y = game.player.position.y - cosf * SHIP_HALF_HEIGHT;
            // Temp vector to center the rotation
            const v1tmp: rl.Vector2 = .{
                .x = game.player.position.x - sinf * SHIP_HALF_HEIGHT,
                .y = game.player.position.y + cosf * SHIP_HALF_HEIGHT,
            };
            game.player.rightPoint.x = v1tmp.x - cosf * (SHIP_HALF_HEIGHT - 2.0);
            game.player.rightPoint.y = v1tmp.y - sinf * (SHIP_HALF_HEIGHT - 2.0);

            game.player.leftPoint.x = v1tmp.x + cosf * (SHIP_HALF_HEIGHT - 2.0);
            game.player.leftPoint.y = v1tmp.y + sinf * (SHIP_HALF_HEIGHT - 2.0);
            if (game.player.isAccelerating) {
                rl.drawCircleV(v1tmp, 4, Color.yellow);
            }
            rl.drawTriangle(game.player.topPoint, game.player.rightPoint, game.player.leftPoint, Color.white);
        },
        GameStateType.StateStartMenu => {
            if (MenuButtom(startMenuRec, "Start Game")) {
                // Initialize game
                game.state = GameStateType.StateInGame;
            }
            if (MenuButtom(exitMenuRec, "Exit Game")) {
                // Exit game
                rl.closeWindow();
            }
        },
        GameStateType.StateGameOver => {
            if (MenuButtom(restartMenuRec, "Restart Game")) {
                // Initialize game
                ResetPlayer();
                game.state = GameStateType.StateInGame;
            }
            if (MenuButtom(exitMenuRec, "Exit Game")) {
                // Exit game
                rl.closeWindow();
            }
        },
    }
    //----------------------------------------------------------------------------------
}
