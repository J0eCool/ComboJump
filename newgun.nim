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
    count
    createSingle
    createSpread
    shoot

  SpellDesc* = seq[Rune]

  ProjectileKind = enum
    single
    spread

  ProjectileInfo = object
    case kind: ProjectileKind
    of single:
      discard
    of spread:
      numBullets: int

  ValueKind = enum
    number
    projectileInfo

  Value = object
    case kind: ValueKind
    of number:
      value: float
    of projectileInfo:
      projectile: ProjectileInfo

proc newBullet(pos, dir: Vec, speed: float): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color(0, 255, 255, 255)),
    newBullet(1.0),
  ])

proc newBulletEvents(projectile: ProjectileInfo, pos, dir: Vec): Events =
  case projectile.kind
  of single:
    let
      speed = 1200.0
      bullet = newBullet(pos, dir, speed)
    bullet.getComponent(Sprite).color = color(255, 255, 0, 255)
    result = @[Event(kind: addEntity, entity: bullet)]
  of spread:
    result = @[]
    let
      speed = 800.0
      num = projectile.numBullets
      angPer = 15.0
      totAng = angPer * (num - 1).float
      baseAng = -totAng / 2
    for i in 0..<num:
      let
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed)
      result.add Event(kind: addEntity, entity: bullet)

proc castAt*(spell: SpellDesc, pos, dir: Vec): Events =
  result = @[]
  var valueStack = newStack[Value]()
  for rune in spell:
    case rune
    of count:
      if valueStack.count == 0 or valueStack.peek.kind != number:
        valueStack.push Value(kind: number, value: 1.0)
      else:
        var num = valueStack.pop
        num.value += 1.0
        valueStack.push num
    of createSingle:
      let proj = ProjectileInfo(kind: single)
      valueStack.push Value(kind: projectileInfo, projectile: proj)
    of createSpread:
      let arg = valueStack.pop
      assert arg.kind == number
      let
        num = arg.value.int
        proj = ProjectileInfo(kind: spread, numBullets: num)
      valueStack.push Value(kind: projectileInfo, projectile: proj)
    of shoot:
      let arg = valueStack.pop
      assert arg.kind == projectileInfo
      result &= arg.projectile.newBulletEvents(pos, dir)

  assert valueStack.count == 0
