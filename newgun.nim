import
  math
from sdl2 import color

import
  component/bullet,
  component/collider,
  component/damage,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  entity,
  event,
  option,
  rect,
  stack,
  vec,
  util


type
  Rune* = enum
    createProjectile
    shoot

  SpellDesc* = seq[Rune]

  Value = enum
    projectileInfo

proc newBullet(pos, dir: Vec, speed: float): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color(0, 255, 255, 255)),
    newBullet(1.0),
  ])

proc castAt*(spell: SpellDesc, pos, dir: Vec): Events =
  result = @[]
  var valueStack = newStack[Value]()
  var speed = 1000.0
  for rune in spell:
    case rune
    of createProjectile:
      valueStack.push projectileInfo
    of shoot:
      discard valueStack.pop
      let bullet = newBullet(pos, dir, speed)
      result.add Event(kind: addEntity, entity: bullet)
      speed += 700.0
