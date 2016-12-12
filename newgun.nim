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
    num
    count
    mult
    createSingle
    createSpread
    createBurst
    despawn
    update
    done

    # update-only runes
    wave
    turn
    grow

  SpellDesc* = seq[Rune]

  ProjectileKind = enum
    single
    spread
    burst

  ProjectileInfo = object
    onDespawn: ref ProjectileInfo
    updateRunes: seq[Rune]
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

  SpellParseKind = enum
    error
    success
  SpellParse* = object
    case kind: SpellParseKind
    of error:
      index: int
      message: string
    of success:
      events: Events

proc textureName*(rune: Rune): string =
  result = "runes/"
  case rune
  of num:
    result &= "Num.png"
  of count:
    result &= "Inc.png"
  of mult:
    result &= "Mult.png"
  of createSingle:
    result &= "Single.png"
  of createSpread:
    result &= "Spread.png"
  of createBurst:
    result &= "Burst.png"
  of despawn:
    result &= "Despawn.png"
  of update:
    result &= "Update.png"
  of done:
    result &= "Done.png"
  of wave:
    result &= "Wave.png"
  of turn:
    result &= "Turn.png"
  of grow:
    result &= "Grow.png"

proc newBullet(pos, dir: Vec, speed: float,
               color: sdl2.Color,
               despawnCallback: proc(pos, vel: Vec): Events,
               updateCallback: proc(entity: Entity, dt: float)): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color),
    newBullet(0.6, despawnCallback, updateCallback),
  ])

proc newBulletEvents(info: ProjectileInfo, pos, dir: Vec): Events =
  let
    despawnCallback =
      if info.onDespawn == nil:
        nil
      else:
        proc(pos, vel: Vec): Events =
          newBulletEvents(info.onDespawn[], pos, vel)
    updateCallback =
      if info.updateRunes == nil:
        nil
      else:
        proc(e: Entity, dt: float) =
          var valueStack = newStack[Value]()
          for rune in info.updateRunes:
            case rune
            of num:
              valueStack.push Value(kind: number, value: 1.0)
            of count:
              var num = valueStack.pop
              assert num.kind == number
              num.value += 1.0
              valueStack.push num
            of mult:
              let a = valueStack.pop
              assert a.kind == number
              let b = valueStack.pop
              assert b.kind == number
              valueStack.push Value(kind: number, value: a.value * b.value)
            of wave:
              let b = e.getComponent(Bullet)
              valueStack.push Value(kind: number, value: cos(1.5 * TAU * b.lifePct))
            of turn:
              let arg = valueStack.pop
              assert arg.kind == number
              let mv = e.getComponent(Movement)
              mv.vel = mv.vel.rotate(360.0.degToRad * arg.value * dt)
            of grow:
              let arg = valueStack.pop
              assert arg.kind == number
              let
                b = e.getComponent(Bullet)
                t = e.getComponent(Transform)
              t.size += vec(arg.value * 160.0 * b.lifePct * dt)
            else:
              assert false, "Invalid update rune: " & $rune
  case info.kind
  of single:
    let
      speed = 1200.0
      color = color(255, 255, 0, 255)
      bullet = newBullet(pos, dir, speed, color, despawnCallback, updateCallback)
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
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback)
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
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback)
      result.add Event(kind: addEntity, entity: bullet)

proc castAt*(spell: SpellDesc, pos, dir: Vec): SpellParse =
  var valueStack = newStack[Value]()
  var i = 0
  template expect(cond: bool, msg: string = "") =
    if not cond:
      return SpellParse(kind: error, index: i, message: msg)
  while i < spell.len:
    let rune = spell[i]
    case rune
    of num:
      valueStack.push Value(kind: number, value: 1.0)
    of count:
      var num = valueStack.pop
      expect num.kind == number
      num.value += 1.0
      valueStack.push num
    of mult:
      let a = valueStack.pop
      expect a.kind == number
      let b = valueStack.pop
      expect b.kind == number
      valueStack.push Value(kind: number, value: a.value * b.value)
    of createSingle:
      let proj = ProjectileInfo(kind: single)
      valueStack.push Value(kind: projectileInfo, info: proj)
    of createSpread, createBurst:
      let arg = valueStack.pop
      expect arg.kind == number
      let
        num = arg.value.int
        projKind =
          case rune
          of createSpread: spread
          of createBurst: burst
          else:
            expect false, "Missing projKind case"
            single
        proj = ProjectileInfo(kind: projKind, numBullets: num)
      valueStack.push Value(kind: projectileInfo, info: proj)
    of despawn:
      let arg = valueStack.pop
      expect arg.kind == projectileInfo
      var proj = valueStack.pop
      expect proj.kind == projectileInfo
      expect proj.info.onDespawn == nil
      var d = new(ProjectileInfo)
      d[] = arg.info
      proj.info.onDespawn = d
      valueStack.push proj
    of update:
      var proj = valueStack.pop
      expect proj.kind == projectileInfo
      expect proj.info.updateRunes == nil
      let begin = i + 1
      while spell[i] != done:
        i += 1
      proj.info.updateRunes = spell[begin..<i]
      valueStack.push proj
    of done, turn, wave, grow:
      expect false, "Invalid context for rune: " & $rune
    i += 1

  let arg = valueStack.pop
  expect valueStack.count == 0
  expect arg.kind == projectileInfo
  return SpellParse(kind: success, events: arg.info.newBulletEvents(pos, dir))

proc handleSpellCast*(parse: SpellParse): Events =
  case parse.kind
  of success:
    return parse.events
  of error:
    echo "Parse error for spell at index ", parse.index, ": ", parse.message
    return @[]
