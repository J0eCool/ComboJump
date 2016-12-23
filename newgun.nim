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
  component/targeting,
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
    moveUp
    moveSide
    nearest
    startPos

  SpellDesc* = seq[Rune]

  ProjectileKind = enum
    single
    spread
    burst

  ProjectileInfo = object
    onDespawn: ref ProjectileInfo
    updateCallbacks: seq[UpdateProc]
    case kind: ProjectileKind
    of single:
      discard
    of spread, burst:
      numBullets: int

  NumberProc = proc(e: Entity): float
  Number = object
    get: NumberProc
  ValueKind = enum
    number
    projectileInfo

  Value = object
    case kind: ValueKind
    of number:
      value: Number
    of projectileInfo:
      info: ProjectileInfo

  SpellParseKind = enum
    error
    success
  SpellParse* = object
    spell: SpellDesc
    case kind: SpellParseKind
    of error:
      index: int
      message: string
    of success:
      fire: (proc(pos, dir: Vec, target: Target): Events)

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
  of moveUp:
    result &= "MoveUp.png"
  of moveSide:
    result &= "MoveSide.png"
  of nearest:
    result &= "Nearest.png"
  of startPos:
    result &= "StartPos.png"

proc newBullet(pos, dir: Vec, speed: float,
               color: sdl2.Color,
               despawnCallback: ShootProc,
               updateCallback: UpdateProc,
               target: Target): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: 5),
    Sprite(color: color),
    Bullet(
      liveTime: 0.6,
      nextStage: despawnCallback,
      onUpdate: updateCallback,
      dir: dir,
      speed: speed,
      target: target,
    ),
  ])

proc newBulletEvents(info: ProjectileInfo, pos, dir: Vec, target: Target): Events =
  let
    despawnCallback =
      if info.onDespawn == nil:
        nil
      else:
        proc(pos, vel: Vec): Events =
          newBulletEvents(info.onDespawn[], pos, vel, target)
    updateCallback =
      if info.updateCallbacks == nil:
        nil
      else:
        proc(e: Entity, dt: float) =
          let
            m = e.getComponent(Movement)
            b = e.getComponent(Bullet)
          m.vel = b.speed * b.dir
          for f in info.updateCallbacks:
            f(e, dt)
  case info.kind
  of single:
    let
      speed = 900.0
      color = color(255, 255, 0, 255)
      bullet = newBullet(pos, dir, speed, color, despawnCallback, updateCallback, target)
    result = @[Event(kind: addEntity, entity: bullet)]
  of spread:
    result = @[]
    let
      speed = 600.0
      color = color(0, 255, 255, 255)
      num = info.numBullets + 1
      angPer = 10.0
      baseAng = 15.0
      totAng = angPer * num.float + baseAng
    for i in 0..<num:
      let
        p = if num == 0: 0.0 else: lerp(i / (num - 1), -1.0, 1.0)
        ang = totAng * p / 2.0
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback, target)
        b = bullet.getComponent(Bullet)
      b.startPos = p
      result.add Event(kind: addEntity, entity: bullet)
  of burst:
    result = @[]
    let
      speed = 600.0
      color = color(255, 0, 255, 255)
      num = info.numBullets * 2
      angPer = 360.0 / num.float
      baseAng = random(0.0, 360.0)
    for i in 0..<num:
      let
        p = if num == 0: 0.0 else: lerp(i / (num - 1), -1.0, 1.0)
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback, target)
        b = bullet.getComponent(Bullet)
      b.startPos = p
      result.add Event(kind: addEntity, entity: bullet)

proc parse*(spell: SpellDesc): SpellParse =
  var
    valueStack = newStack[Value]()
    updateContext: seq[UpdateProc] = nil
    i = 0
  template expect(cond: bool, msg: string = "") =
    if not cond:
      return SpellParse(kind: error, spell: spell, index: i, message: msg)
  while i < spell.len:
    let rune = spell[i]
    case rune
    of num:
      let
        f = proc(e: Entity): float = 1.0
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    of count:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      var num = valueStack.pop
      expect num.kind == number
      let
        # Need this to wrap the closure of num.value so it doesn't get lost
        # by runes like [num, count, count]
        makeProc = proc(v: Number): NumberProc =
          result = proc(e:Entity): float =
            v.get(e) + 1.0
      let
        f = makeProc(num.value)
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    of mult:
      expect valueStack.count >= 2, "Needs at least 2 arguments"
      let a = valueStack.pop
      expect a.kind == number
      let b = valueStack.pop
      expect b.kind == number
      let
        makeProc = proc(v1, v2: Number): NumberProc =
          result = proc(e: Entity): float = v1.get(e) * v2.get(e)
        n = Number(get: makeProc(a.value, b.value))
      valueStack.push Value(kind: number, value: n)
    of createSingle:
      let proj = ProjectileInfo(kind: single)
      valueStack.push Value(kind: projectileInfo, info: proj)
    of createSpread, createBurst:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      let arg = valueStack.pop
      expect arg.kind == number
      let
        num = arg.value.get(nil).int
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
      expect valueStack.count >= 2, "Needs at least 2 arguments"
      let arg = valueStack.pop
      expect arg.kind == projectileInfo, "Expects projectileInfo as first argument"
      var proj = valueStack.pop
      expect proj.kind == projectileInfo, "Expects projectileInfo as second argument"
      expect proj.info.onDespawn == nil
      var d = new(ProjectileInfo)
      d[] = arg.info
      proj.info.onDespawn = d
      valueStack.push proj
    of update:
      expect valueStack.count >= 1
      expect(updateContext == nil, "Invalid in an update context")
      var proj = valueStack.peek
      expect proj.kind == projectileInfo, "Expects projectileInfo argument"
      updateContext = @[]
    of done:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      expect(updateContext != nil, "Needs an update context")
      var proj = valueStack.pop
      expect proj.kind == projectileInfo, "Expects projectileInfo argument"
      expect proj.info.updateCallbacks == nil, "Expected projectileInfo updateCallbacks to be nil"
      proj.info.updateCallbacks = updateContext
      updateContext = nil
      valueStack.push proj
    of wave:
      expect(updateContext != nil, "Needs an update context")
      let
        f = proc(e: Entity): float =
          let b = e.getComponent(Bullet)
          cos(1.5 * TAU * b.lifePct)
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    of turn:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      expect(updateContext != nil, "Needs an update context")
      let arg = valueStack.pop
      expect arg.kind == number
      let f = proc(e: Entity, dt: float) =
        let b = e.getComponent(Bullet)
        b.dir = b.dir.rotate(360.0.degToRad * arg.value.get(e) * dt)
      updateContext.add f
    of grow:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      expect(updateContext != nil, "Needs an update context")
      let arg = valueStack.pop
      expect arg.kind == number
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          t = e.getComponent(Transform)
          m = e.getComponent(Movement)
        t.size += vec(arg.value.get(e) * 160.0 * b.lifePct * dt)
        m.vel -= b.dir * b.speed
      updateContext.add f
    of moveUp:
      expect valueStack.count >= 1, "Needs at least 1 argument"
      expect(updateContext != nil, "Needs an update context")
      let arg = valueStack.pop
      expect arg.kind == number
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          m = e.getComponent(Movement)
        m.vel += (b.speed * arg.value.get(e) / 2.0) * b.dir
      updateContext.add f
    of moveSide:
      # Copy pasted from moveUp for now. There's an issue with closures capturing
      # inconvenient local vars, that needs to be worked around less-hackily.
      expect valueStack.count >= 1, "Needs at least 1 argument"
      expect(updateContext != nil, "Needs an update context")
      let arg = valueStack.pop
      expect arg.kind == number
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          m = e.getComponent(Movement)
        m.vel += (b.speed * arg.value.get(e) / 2.0) * b.dir.rotate(PI / 2)
      updateContext.add f
    of nearest:
      expect(updateContext != nil, "Needs an update context")
      let f = proc(e:Entity): float =
        let
          b = e.getComponent(Bullet)
          t = e.getComponent(Transform)
        b.target.tryPos.bindAs targetPos:
          let
            diff = targetPos - t.pos
            lv = min((1.0 - b.lifePct) / 0.4, 1.0)
          result = b.dir.cross(diff).sign.float * lv
      valueStack.push(Value(kind: number, value: Number(get: f)))
    of startPos:
      expect(updateContext != nil, "Needs an update context")
      let f = proc(e:Entity): float =
        let b = e.getComponent(Bullet)
        b.startPos
      valueStack.push(Value(kind: number, value: Number(get: f)))
    i += 1

  expect(valueStack.count == 1, "Needs exactly one argument at spell end")
  let arg = valueStack.pop
  expect(arg.kind == projectileInfo, "Spell must end with projectile")
  expect(updateContext == nil, "Spell must end without update context")
  let fireProc = proc(pos, dir: Vec, target: Target): Events =
    arg.info.newBulletEvents(pos, dir, target)
  return SpellParse(kind: success, spell: spell, fire: fireProc)

proc handleSpellCast*(parse: SpellParse, pos, dir: Vec, target: Target): Events =
  case parse.kind
  of success:
    return parse.fire(pos, dir, target)
  of error:
    var errMsg = "Parse error for spell at "
    if parse.index < parse.spell.len:
      let rune = parse.spell[parse.index]
      errMsg &= "rune " & $rune & "(idx=" & $parse.index & ")"
    else:
      errMsg &= "spell end"
    errMsg &= ": "
    if parse.message != nil:
      errMsg &= parse.message
    else:
      errMsg &= "Invalid SpellParse"
    echo errMsg
    return @[]
