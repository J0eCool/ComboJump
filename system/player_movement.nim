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
  speed = 380.0
  accelTime = 0.1
  accel = speed / accelTime
  jumpHeight = 250.0

proc playerMovement*(entities: seq[Entity], dt: float): Events =
  entities.forComponents e, [
    Movement, m,
    PlayerControl, p,
    Transform, t,
    Collider, c,
  ]:
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

    if t.pos.y >= 800 or p.jumpPressed and m.onGround:
      m.vel.y = jumpSpeed(jumpHeight)
