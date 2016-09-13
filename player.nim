import math, sdl2

import entity, input, vec, util

type Player* = ref object of Entity
  started: bool
  vel: Vec

proc newPlayer*(): Player =
  Player(
    pos: vec(500, 600),
    size: vec(80, 100),
    color: color(55, 38, 255, 255),
  )

const
  speed = 280.0
  accel = 1_400.0
  gravity = 2_100.0
  jumpHeight = 500.0
  jumpSpeed = -sign(gravity).float * sqrt(2 * jumpHeight * abs(gravity))


proc update*(player: Player, dt: float, input: InputManager) =
  if input.isPressed(Input.jump):
    player.started = true
    player.vel.y = jumpSpeed

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

  if player.started:
    player.vel.y += gravity * dt
    if player.vel.y < 0 and not input.isHeld(Input.jump):
      player.vel.y += 1.5 * gravity * dt
  if player.pos.y >= 800 and player.vel.y > 0:
    player.vel.y = jumpSpeed

  let toMove = player.vel * dt
  player.move(toMove)
