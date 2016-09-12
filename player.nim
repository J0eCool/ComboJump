import math, sdl2

import game_object, input, vec, util

type Player* = ref object of GameObject
  started: bool
  vel: Vec

proc newPlayer*(): Player =
  Player(
    pos: vec(500, 200),
    size: vec(80, 100),
    color: color(55, 38, 255, 255),
  )

const
  speed = 280.0
  accel = 1400.0
  gravity = 240.0

proc update*(player: Player, dt: float, input: InputManager) =
  if input.isPressed(Input.jump):
    player.started = true

  var inputDir = 0
  if input.isHeld(Input.left):
    inputDir -= 1
  if input.isHeld(Input.right):
    inputDir += 1
  var dir = inputDir.float
  let preSign = sign(player.vel.x)
  if dir == 0:
    dir = -0.5 * preSign.float
  player.vel.x += accel * dir.float * dt
  player.vel.x = clamp(player.vel.x, -speed, speed)
  if inputDir == 0 and preSign != sign(player.vel.x):
    player.vel.x = 0
  if player.vel.x != 0:
    echo player.vel.x
  let toMove = player.vel * dt
  player.move(toMove)
