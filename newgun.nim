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
    despawn

  SpellDesc* = seq[Rune]

  ProjectileKind = enum
    single
    spread

  ProjectileInfo = object
    onDespawn: ref ProjectileInfo
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

proc newBulletEvents(projectile: ProjectileInfo, pos, dir: Vec): Events
proc newBullet(pos, dir: Vec, speed: float, despawnCallback: proc(pos, vel: Vec): Events): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color(0, 255, 255, 255)),
    newBullet(0.6, despawnCallback),
  ])

proc newBulletEvents(projectile: ProjectileInfo, pos, dir: Vec): Events =
  let despawnCallback =
    if projectile.onDespawn == nil:
      nil
    else:
      proc(pos, vel: Vec): Events =
        newBulletEvents(projectile.onDespawn[], pos, vel)
  case projectile.kind
  of single:
    let
      speed = 1200.0
      bullet = newBullet(pos, dir, speed, despawnCallback)
    bullet.getComponent(Sprite).color = color(255, 255, 0, 255)
    result = @[Event(kind: addEntity, entity: bullet)]
  of spread:
    result = @[]
    let
      speed = 400.0
      num = projectile.numBullets
      angPer = 15.0
      totAng = angPer * (num - 1).float
      baseAng = -totAng / 2
    for i in 0..<num:
      let
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, despawnCallback)
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
      valueStack.push Value(kind: projectileInfo, projectile: proj)
    of createSpread:
      let arg = valueStack.pop
      assert arg.kind == number
      let
        num = arg.value.int
        proj = ProjectileInfo(kind: spread, numBullets: num)
      valueStack.push Value(kind: projectileInfo, projectile: proj)
    of despawn:
      let arg = valueStack.pop
      assert arg.kind == projectileInfo
      var proj = valueStack.pop
      assert proj.kind == projectileInfo
      assert proj.projectile.onDespawn == nil
      var d = new(ProjectileInfo)
      d[] = arg.projectile
      proj.projectile.onDespawn = d
      valueStack.push proj

  let arg = valueStack.pop
  assert valueStack.count == 0
  assert arg.kind == projectileInfo
  return arg.projectile.newBulletEvents(pos, dir)
