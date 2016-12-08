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
    createBurst
    despawn

  SpellDesc* = seq[Rune]

  ProjectileKind = enum
    single
    spread
    burst

  ProjectileInfo = object
    onDespawn: ref ProjectileInfo
    case kind: ProjectileKind
    of single:
      discard
    of spread, burst:
      numBullets: int

  ValueKind = enum
    number
    projectileInfo

  Value = object
    case kind: ValueKind
    of number:
      value: float
    of projectileInfo:
      info: ProjectileInfo

proc newBulletEvents(info: ProjectileInfo, pos, dir: Vec): Events
proc newBullet(pos, dir: Vec, speed: float,
               color: sdl2.Color,
               despawnCallback: proc(pos, vel: Vec): Events): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color),
    newBullet(0.6, despawnCallback),
  ])

proc newBulletEvents(info: ProjectileInfo, pos, dir: Vec): Events =
  let despawnCallback =
    if info.onDespawn == nil:
      nil
    else:
      proc(pos, vel: Vec): Events =
        newBulletEvents(info.onDespawn[], pos, vel)
  case info.kind
  of single:
    let
      speed = 1200.0
      color = color(255, 255, 0, 255)
      bullet = newBullet(pos, dir, speed, color, despawnCallback)
    result = @[Event(kind: addEntity, entity: bullet)]
  of spread:
    result = @[]
    let
      speed = 600.0
      color = color(0, 255, 255, 255)
      num = info.numBullets
      angPer = 20.0
      totAng = angPer * (num - 1).float
      baseAng = -totAng / 2
    for i in 0..<num:
      let
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback)
      result.add Event(kind: addEntity, entity: bullet)
  of burst:
    result = @[]
    let
      speed = 600.0
      color = color(255, 0, 255, 255)
      num = info.numBullets * 2
      angPer = 360.0 / num.float
      baseAng = angPer / 2
    for i in 0..<num:
      let
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback)
      result.add Event(kind: addEntity, entity: bullet)

proc castAt*(spell: SpellDesc, pos, dir: Vec): Events =
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
      valueStack.push Value(kind: projectileInfo, info: proj)
    of createSpread, createBurst:
      let arg = valueStack.pop
      assert arg.kind == number
      let
        num = arg.value.int
        projKind =
          case rune
          of createSpread: spread
          of createBurst: burst
          else:
            assert false, "Missing projKind case"
            single
        proj = ProjectileInfo(kind: projKind, numBullets: num)
      valueStack.push Value(kind: projectileInfo, info: proj)
    of despawn:
      let arg = valueStack.pop
      assert arg.kind == projectileInfo
      var proj = valueStack.pop
      assert proj.kind == projectileInfo
      assert proj.info.onDespawn == nil
      var d = new(ProjectileInfo)
      d[] = arg.info
      proj.info.onDespawn = d
      valueStack.push proj

  let arg = valueStack.pop
  assert valueStack.count == 0
  assert arg.kind == projectileInfo
  return arg.info.newBulletEvents(pos, dir)
