import math

import
  component/collider,
  component/movement,
  component/player_control,
  component/transform,
  entity,
  event,
  vec,
  util


const
  speed = 320.0
  accelTime = 0.1
  accel = speed / accelTime
  jumpHeight = 250.0
  jumpSpeed = -sign(gravity).float * sqrt(2 * jumpHeight * abs(gravity))

proc playerMovement*(entities: seq[Entity], dt: float): Events =
  forComponents(entities, e, [
    Movement, m,
    PlayerControl, p,
    Transform, t,
    Collider, c,
  ]):
    var dir = p.moveDir.float
    let preSign = sign(m.vel.x)
    if dir == 0:
      dir = -0.5 * preSign.float
    m.vel.x += accel * dir.float * dt
    m.vel.x = clamp(m.vel.x, -speed, speed)
    if p.moveDir == 0 and preSign != sign(m.vel.x):
      m.vel.x = 0

    if m.vel.y < 0 and p.jumpReleased:
      m.vel.y *= 0.25

    t.pos.x = clamp(t.pos.x, 0, 1200 - t.size.x)
    if t.pos.y >= 800 or p.jumpPressed and m.onGround:
      m.vel.y = jumpSpeed
