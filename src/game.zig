const rl = @import("raylib");
const std = @import("std");
const math = std.math;
const Color = rl.Color;

const PLAYER_SPEED: f32 = 100.0;
const PLAYER_ROTATION_SPEED: f32 = 100.0;
const MAX_PLAYER_BULLETS: u8 = 20;
const PLAYER_SHOT_CD: u8 = 20;
const PLAYER_SHOT_SPEED: f32 = 300;
const PLAYER_SHOT_LIFETIME: u16 = 100;
const SHIP_HALF_HEIGHT: f32 = 5.0 / 0.363970;
const PHYSICS_TIME: f32 = 0.02;
const FONT_SIZE: i8 = 20;
const DEG2RAD = 3.14159265358979323846 / 100.0;

const Bullet = struct {
    position: rl.Vector2 = .{ .x = 0, .y = 0 },
    rotation: f32 = 0,
    lifeTime: u16 = 0,
    acceleration: f32 = 10,
    speed: rl.Vector2 = .{ .x = 0, .y = 0 },
};

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
    amountActiveBullets: u8 = 0,
    shotCooldown: u8 = 0,
    bulletsPoll: [MAX_PLAYER_BULLETS]Bullet = std.mem.zeroes([MAX_PLAYER_BULLETS]Bullet),
    fn updatePhysics(self: *Player) void {
        const direction: rl.Vector2 = .{ .x = math.sin(self.rotation * DEG2RAD), .y = -math.cos(self.rotation * DEG2RAD) };
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
        const norm_speed = rl.Vector2.normalize(self.speed);
        if (self.isAccelerating) {
            self.speed = rl.Vector2.scale(rl.Vector2.add(norm_vector, norm_speed), self.acceleration * PHYSICS_TIME);
        } else {
            self.speed = rl.Vector2.scale(norm_speed, self.acceleration * PHYSICS_TIME);
        }
        self.position = rl.Vector2.add(self.position, self.speed);
        // Update Triangle Rotation
        if (rl.Vector2.length(self.speed) > 0.0) {
            if (self.position.x > game.fwidth + SHIP_HALF_HEIGHT) {
                self.position.x = -SHIP_HALF_HEIGHT;
            } else if (self.position.x < -SHIP_HALF_HEIGHT) {
                self.position.x = game.fwidth + SHIP_HALF_HEIGHT;
            }

            if (self.position.y > game.fheight + SHIP_HALF_HEIGHT) {
                self.position.y = -SHIP_HALF_HEIGHT;
            } else if (self.position.y < -SHIP_HALF_HEIGHT) {
                self.position.y = game.fheight + SHIP_HALF_HEIGHT;
            }
        }
    }
    fn shot(self: *Player) bool {
        if (self.shotCooldown > 0) {
            return false;
        }
        self.shotCooldown = PLAYER_SHOT_CD;
        if (self.amountActiveBullets < MAX_PLAYER_BULLETS) {
            self.bulletsPoll[self.amountActiveBullets].position = self.topPoint;
            self.bulletsPoll[self.amountActiveBullets].rotation = self.rotation;
            self.bulletsPoll[self.amountActiveBullets].lifeTime = PLAYER_SHOT_LIFETIME;
            self.bulletsPoll[self.amountActiveBullets].acceleration = PLAYER_SHOT_SPEED;
            self.amountActiveBullets += 1;
            std.debug.print("Peww\n", .{});
            return true;
        }
        return false;
    }
    fn killBullet(self: *Player, i: usize) void {
        self.amountActiveBullets -= 1;
        self.bulletsPoll[i] = self.bulletsPoll[self.amountActiveBullets];
    }
};

pub const GameStateType = enum(u2) {
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
    isPlaying: bool = false,
};
pub threadlocal var isTesting: bool = false;

pub threadlocal var game: Game = .{};
const menu_size_width: f32 = 200.0;
const item_menu_size_height: f32 = 50.0;
const acceleration: f32 = PLAYER_SPEED * PHYSICS_TIME;
threadlocal var exitMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
threadlocal var startMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
threadlocal var restartMenuRec: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };

pub fn startGame() void {
    game.width = 640;
    game.height = 360;
    game.isPlaying = true;

    if (!isTesting) {
        rl.initWindow(game.width, game.height, "Space Zig");
    }

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

pub fn updateFrame() bool {
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
        if (rl.isKeyDown(rl.KeyboardKey.space)) {
            _ = game.player.shot();
        }

        // Physics
        game.frameTimeAccumulator += rl.getFrameTime();
        if (game.frameTimeAccumulator > PHYSICS_TIME) {
            updatePhysics();
        }
    }
    if (!isTesting) {
        drawFrame();
    }
    if (rl.isKeyDown(rl.KeyboardKey.escape) or rl.windowShouldClose()) {
        game.isPlaying = false;
    }
    return game.isPlaying;
}
pub fn updatePhysics() void {
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

    // Calc cooldowns
    if (game.player.shotCooldown > 0) {
        game.player.shotCooldown -= 1;
    }
    for (0.., game.player.bulletsPoll[0..game.player.amountActiveBullets]) |i, *bullet| {
        if (bullet.lifeTime > 0) {
            bullet.lifeTime -= 1;

            const direction: rl.Vector2 = .{ .x = math.sin(bullet.rotation * DEG2RAD), .y = -math.cos(bullet.rotation * DEG2RAD) };
            const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
            bullet.speed = rl.Vector2.scale(norm_vector, bullet.acceleration * PHYSICS_TIME);
            bullet.position = rl.Vector2.add(bullet.position, bullet.speed);
        } else {
            game.player.killBullet(i);
        }
    }
    game.player.updatePhysics();
}
pub fn drawFrame() void {

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

            for (game.player.bulletsPoll[0..game.player.amountActiveBullets]) |bullet| {
                rl.drawCircleV(bullet.position, 4, Color.yellow);
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
                game.isPlaying = false;
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
                game.isPlaying = false;
            }
        },
    }
}
