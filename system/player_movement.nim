import math

import component/player_control,
       component/movement,
       component/transform,
       entity,
       vec,
       util


const
  speed = 280.0
  accel = 1_400.0
  gravity = 2_100.0
  jumpHeight = 500.0
  jumpSpeed = -sign(gravity).float * sqrt(2 * jumpHeight * abs(gravity))

proc playerMovement*(entities: seq[Entity], dt: float) =
  for e in entities:
    let
      m = e.getComponent(Movement)
      p = e.getComponent(PlayerControl)
      t = e.getComponent(Transform)
    if m != nil and p != nil and t != nil:
      var dir = p.moveDir.float
      let preSign = sign(m.vel.x)
      if dir == 0:
        dir = -0.5 * preSign.float
      m.vel.x += accel * dir.float * dt
      m.vel.x = clamp(m.vel.x, -speed, speed)
      if p.moveDir == 0 and preSign != sign(m.vel.x):
        m.vel.x = 0

      if p.jumpStarted:
        m.vel.y += gravity * dt
      if m.vel.y < 0 and not p.jumpHeld:
        m.vel.y += 1.5 * gravity * dt
      if t.pos.y >= 800 and m.vel.y > 0:
        m.vel.y = jumpSpeed
