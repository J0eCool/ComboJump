import
  math

import
  component/[
    bullet,
    collider,
    damage,
    mana,
    movement,
    transform,
    sprite,
  ],
  spells/[
    runes,
    rune_info,
  ],
  color,
  entity,
  event,
  logging,
  option,
  player_stats,
  rect,
  stack,
  vec,
  util

type
  SpellParseKind* = enum
    error
    success
  SpellParse* = object
    spell: SpellDesc
    valueStacks*: seq[seq[ValueKind]]
    instantFire*: bool
    case kind*: SpellParseKind
    of error:
      index*: int
      message: string
    of success:
      fire*: (proc(pos, dir: Vec, stats: PlayerStats): Events)

proc `==`*(a, b: SpellParse): bool =
  if a.kind != b.kind or a.valueStacks != b.valueStacks:
    return false
  case a.kind
  of error:
    return a.index == b.index and a.message == b.message
  of success:
    return a.fire == b.fire

proc manaCost*(spell: SpellParse): int =
  result = 2
  for stack in spell.valueStacks:
    result += stack.len

proc castTime*(spell: SpellParse, stats: PlayerStats): float =
  result = 0.325 + 0.065 * (spell.valueStacks.len - 1).float
  result /= stats.castSpeed
  if spell.instantFire:
    result /= 2.0

proc damage*(spell: SpellParse, stats: PlayerStats): float =
  (5 + 0.25 * (spell.spell.len - 1).float) * stats.damage

proc newBullet(pos, dir: Vec, speed: float,
               color: Color,
               despawnCallback: ShootProc,
               updateCallback: UpdateProc,
               damage: int): Entity =
  newEntity("Bullet", [
    Transform(pos: pos, size: vec(20)),
    Movement(vel: speed * dir),
    Collider(layer: Layer.bullet),
    Damage(damage: damage),
    Sprite(color: color),
    Bullet(
      liveTime: 0.6,
      nextStage: despawnCallback,
      onUpdate: updateCallback,
      dir: dir,
      speed: speed,
      randomNum: random(-1.0, 1.0),
    ),
  ])

proc newBulletEvents(info: ProjectileInfo, pos, dir: Vec, damage: float): Events =
  let
    baseDamage = info.damage * damage
    despawnCallback =
      if info.onDespawn == nil:
        nil
      else:
        proc(pos, vel: Vec): Events =
          newBulletEvents(info.onDespawn[], pos, vel, baseDamage)
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
      color = rgb(255, 255, 0)
      bullet = newBullet(pos, dir, speed, color, despawnCallback, updateCallback, baseDamage.int)
    result = @[Event(kind: addEntity, entity: bullet)]
  of spread:
    result = @[]
    let
      speed = 600.0
      color = rgb(0, 255, 255)
      num = info.numBullets + 1
      angPer = 10.0
      baseAng = 15.0
      totAng = angPer * num.float + baseAng
    for i in 0..<num:
      let
        p = if num == 0: 0.0 else: lerp(i / (num - 1), -1.0, 1.0)
        ang = totAng * p / 2.0
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback, baseDamage.int)
        b = bullet.getComponent(Bullet)
      b.startPos = p
      result.add Event(kind: addEntity, entity: bullet)
  of burst:
    result = @[]
    let
      speed = 600.0
      color = rgb(255, 0, 255)
      num = info.numBullets * 2
      angPer = 360.0 / num.float
      baseAng = random(0.0, 360.0)
    for i in 0..<num:
      let
        p = if num == 0: 0.0 else: lerp(i / (num - 1), -1.0, 1.0)
        ang = baseAng + angPer * i.float
        curDir = dir.rotate(ang.degToRad)
        bullet = newBullet(pos, curDir, speed, color, despawnCallback, updateCallback, baseDamage.int)
        b = bullet.getComponent(Bullet)
      b.startPos = p
      result.add Event(kind: addEntity, entity: bullet)
  of repeat:
    let
      toShoot =
        proc(pos, vel: Vec): Events =
          newBulletEvents(info.repeatInfo[], pos, vel, baseDamage)
      num = info.numRepeats + 1
      repeater = newEntity("Repeater", [
        Transform(pos: pos),
        RepeatShooter(
          numToRepeat: num,
          toShoot: toShoot,
          nextStage: despawnCallback,
          dir: dir,
        ),
      ])
    result = @[Event(kind: addEntity, entity: repeater)]

proc parse*(spell: SpellDesc): SpellParse =
  var
    valueStack = newStack[Value]()
    valueStacks: seq[seq[ValueKind]] = @[]
    i = 0
  proc toKinds(values: Stack[Value]): seq[ValueKind] =
    result = @[]
    for value in values:
      result.add value.kind
  template expect(cond: bool, msg: string = "") =
    if not cond:
      var stackTypes = "\nStack: " & $valueStack.toKinds()
      return SpellParse(kind: error, spell: spell, index: i, message: msg & stackTypes, valueStacks: valueStacks)
  while i < spell.len:
    let rune = spell[i]
    for x in 0..<rune.info.input.len:
      let
        q = valueStack.toSeq()
        k = q.len - 1 - x
      expect k >= 0, "Needs at least " & $rune.info.input.len & " arguments"
      expect q[k].kind == rune.info.input[x], "Needs argument " & $(x + 1) & " to be a " & $rune.info.input[x]
    let r = rune.info.parse(valueStack)
    r.bindAs r:
      expect false, r
    i += 1
    valueStacks.add valueStack.toKinds()

  expect(valueStack.count == 1, "Needs exactly one argument at spell end")
  let arg = valueStack.pop
  expect(arg.kind == projectileInfo, "Spell must end with projectile")

  var parse = SpellParse(
    kind: success,
    spell: spell,
    valueStacks: valueStacks,
    instantFire: true,
  )
  let fireProc = proc(pos, dir: Vec, stats: PlayerStats): Events =
    arg.info.newBulletEvents(pos, dir, parse.damage(stats))
  parse.fire = fireProc
  return parse

proc canCast*(parse: SpellParse): bool =
  case parse.kind
  of success:
    result = true
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
    log LogLevel.info, errMsg
