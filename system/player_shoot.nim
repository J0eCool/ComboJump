import sdl2

import
  component/bullet,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  entity,
  rect,
  vec,
  util


const
  speed = 1500.0

proc playerShoot*(entities: seq[Entity]): seq[Entity] =
  forComponents(entities, e, [
    PlayerControl, p,
    Transform, t,
  ]):
    result = @[]
    if p.shootPressed:
      let
        size = vec(20, 20)
        shotPoint = t.rect.center + vec(t.size.x * 0.5 * p.facing.float - size.x / 2, -size.y / 2)
      result.add(newEntity("Bullet", [
        Transform(pos: shotPoint, size: size),
        Movement(vel: vec(p.facing.float * speed, 0.0)),
        Sprite(color: color(255, 255, 32, 255)),
        Bullet(damage: 1, liveTime: 1.5),
      ]))
