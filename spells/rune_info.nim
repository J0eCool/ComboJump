import
  algorithm,
  math

import
  component/[
    bullet,
    movement,
    targeting,
    transform,
  ],
  spells/runes,
  entity,
  option,
  stack,
  vec,
  util

type
  ProjectileKind* = enum
    single
    spread
    burst
    repeat

  ProjectileInfo* = object
    onDespawn*: ref ProjectileInfo
    updateCallbacks*: seq[UpdateProc]
    case kind*: ProjectileKind
    of single:
      discard
    of spread, burst:
      numBullets*: int
    of repeat:
      numRepeats*: int
      repeatInfo*: ref ProjectileInfo

  NumberProc* = proc(e: Entity): Option[float]
  Number* = object
    get*: NumberProc
  ValueKind* = enum
    number
    projectileInfo

  Value* = object
    case kind*: ValueKind
    of number:
      value*: Number
    of projectileInfo:
      info*: ProjectileInfo
  ValueStack = Stack[Value]

  RuneParse = Option[string]
  RuneParseProc = proc(valueStack: var ValueStack): RuneParse
  RuneInfo* = object
    texture*: string
    input*: seq[ValueKind]
    output: seq[ValueKind]
    parse*: RuneParseProc

proc info*(rune: Rune): RuneInfo

proc textureName*(rune: Rune): string =
  "runes/" & rune.info.texture

proc textureName*(kind: ValueKind): string =
  case kind
  of number:
    "redGlobe.png"
  of projectileInfo:
    "greenGlobe.png"

proc inputSeq*(info: RuneInfo): seq[ValueKind] =
  info.input.reversed
proc outputSeq*(info: RuneInfo): seq[ValueKind] =
  info.output.reversed

proc damage*(projectile: ProjectileInfo): float =
  case projectile.kind:
  of single:
    1.0
  of spread:
    8 / (10 + (projectile.numBullets - 1))
  of burst:
    8 / (10 + 2 * (projectile.numBullets - 1))
  of repeat:
    7 / (10 + 2 * (projectile.numRepeats - 1))

template expect(cond: bool, msg: string = "") =
  if not cond:
    return makeJust(msg)

proc addUpdateProc(valueStack: var ValueStack, update: UpdateProc) =
  var proj = valueStack.pop
  if proj.info.updateCallbacks == nil:
    proj.info.updateCallbacks = @[]
  proj.info.updateCallbacks.add(update)
  valueStack.push proj

proc makeCountProc(v: Number): NumberProc =
  result = proc(e:Entity): Option[float] =
    v.get(e).bindAs x:
      return makeJust(x + 1.0)
    return makeNone[float]()

proc makeMultProc(n1, n2: Number): NumberProc =
  result = proc(e: Entity): Option[float] =
    n1.get(e).bindAs x1:
      n2.get(e).bindAs x2:
        return makeJust(x1 * x2)
    return makeNone[float]()

proc numRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Num.png",
    input: @[],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let
        f = proc(e: Entity): Option[float] = makeJust(1.0)
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    ),
  )

proc countRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Inc.png",
    input: @[number],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      var num = valueStack.pop
      let
        f = makeCountProc(num.value)
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    ),
  )

proc multRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Mult.png",
    input: @[number, number],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let a = valueStack.pop
      let b = valueStack.pop
      let n = Number(get: makeMultProc(a.value, b.value))
      valueStack.push Value(kind: number, value: n)
    ),
  )

proc createSingleRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Single.png",
    input: @[],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let proj = ProjectileInfo(kind: single)
      valueStack.push Value(kind: projectileInfo, info: proj)
    ),
  )

proc createSpreadRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Spread.png",
    input: @[number],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let rawNum = arg.value.get(nil)
      expect rawNum.kind == just, "Needs statically determinable number"
      let
        num = rawNum.value.int
        proj = ProjectileInfo(kind: spread, numBullets: num)
      valueStack.push Value(kind: projectileInfo, info: proj)
    ),
  )

proc createBurstRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Burst.png",
    input: @[number],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let rawNum = arg.value.get(nil)
      expect rawNum.kind == just, "Needs statically determinable number"
      let
        num = rawNum.value.int
        proj = ProjectileInfo(kind: burst, numBullets: num)
      valueStack.push Value(kind: projectileInfo, info: proj)
    ),
  )

proc createRepeatRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Repeat.png",
    input: @[number, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let
        arg = valueStack.pop
        repeatProj = valueStack.pop
        rawNum = arg.value.get(nil)
      expect rawNum.kind == just, "Needs statically determinable number"
      var r = new(ProjectileInfo)
      r[] = repeatProj.info
      let
        num = rawNum.value.int
        proj = ProjectileInfo(kind: repeat, numRepeats: num, repeatInfo: r)
      valueStack.push Value(kind: projectileInfo, info: proj)
    ),
  )

proc despawnRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Despawn.png",
    input: @[projectileInfo, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      var
        proj = valueStack.pop
        projToAdd = addr proj.info
      while projToAdd.onDespawn != nil:
        projToAdd = addr projToAdd.onDespawn[]
      var d = new(ProjectileInfo)
      d[] = arg.info
      projToAdd.onDespawn = d
      valueStack.push proj
    ),
  )

proc waveRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Wave.png",
    input: @[],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let
        f = proc(e: Entity): Option[float] =
          if e == nil:
            return makeNone[float]()
          let b = e.getComponent(Bullet)
          return makeJust(cos(1.5 * TAU * b.lifePct))
        n = Number(get: f)
      valueStack.push Value(kind: number, value: n)
    ),
  )

proc turnRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Turn.png",
    input: @[number, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let f = proc(e: Entity, dt: float) =
        let b = e.getComponent(Bullet)
        b.dir = b.dir.rotate(360.0.degToRad * arg.value.get(e).value * dt)
      valueStack.addUpdateProc(f)
    ),
  )

proc growRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Grow.png",
    input: @[number, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          t = e.getComponent(Transform)
          m = e.getComponent(Movement)
        b.stayOnHit = true
        t.size += vec(arg.value.get(e).value * 160.0 * b.lifePct * dt)
        m.vel -= b.dir * b.speed
      valueStack.addUpdateProc(f)
    ),
  )

proc moveUpRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "MoveUp.png",
    input: @[number, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          m = e.getComponent(Movement)
        m.vel += (b.speed * arg.value.get(e).value / 2.0) * b.dir
      valueStack.addUpdateProc(f)
    ),
  )

proc moveSideRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "MoveSide.png",
    input: @[number, projectileInfo],
    output: @[projectileInfo],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let arg = valueStack.pop
      let f = proc(e: Entity, dt: float) =
        let
          b = e.getComponent(Bullet)
          m = e.getComponent(Movement)
        m.vel += (b.speed * arg.value.get(e).value / 2.0) * b.dir.rotate(PI / 2)
      valueStack.addUpdateProc(f)
    ),
  )

proc nearestRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Nearest.png",
    input: @[],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let f = proc(e:Entity): Option[float] =
        assert false, "TODO: Implement real Nearest rune"
        makeNone[float]()
        # if e == nil:
        #   return makeNone[float]()
        # let
        #   b = e.getComponent(Bullet)
        #   t = e.getComponent(Transform)
        # result = makeJust(0.0)
        # b.target.tryPos.bindAs targetPos:
        #   let
        #     diff = targetPos - t.pos
        #     lv = min((1.0 - b.lifePct) / 0.4, 1.0)
        #   result = makeJust(b.dir.cross(diff).sign.float * lv)
      valueStack.push(Value(kind: number, value: Number(get: f)))
    ),
  )

proc startPosRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "StartPos.png",
    input: @[],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let f = proc(e:Entity): Option[float] =
        if e == nil:
          return makeNone[float]()
        let b = e.getComponent(Bullet)
        makeJust(b.startPos)
      valueStack.push(Value(kind: number, value: Number(get: f)))
    ),
  )

proc randomRuneInfo(): RuneInfo =
  RuneInfo(
    texture: "Random.png",
    input: @[],
    output: @[number],
    parse: (proc(valueStack: var ValueStack): RuneParse =
      let f = proc(e:Entity): Option[float] =
        if e == nil:
          return makeNone[float]()
        let b = e.getComponent(Bullet)
        makeJust(b.randomNum)
      valueStack.push(Value(kind: number, value: Number(get: f)))
    ),
  )

proc runeInfos_init(): array[Rune, RuneInfo] =
  result[num] = numRuneInfo()
  result[count] = countRuneInfo()
  result[mult] = multRuneInfo()
  result[createSingle] = createSingleRuneInfo()
  result[createSpread] = createSpreadRuneInfo()
  result[createBurst] = createBurstRuneInfo()
  result[createRepeat] = createRepeatRuneInfo()
  result[despawn] = despawnRuneInfo()
  result[wave] = waveRuneInfo()
  result[turn] = turnRuneInfo()
  result[grow] = growRuneInfo()
  result[moveUp] = moveUpRuneInfo()
  result[moveSide] = moveSideRuneInfo()
  result[nearest] = nearestRuneInfo()
  result[startPos] = startPosRuneInfo()
  result[random] = randomRuneInfo()
const runeInfos = runeInfos_init()

proc info*(rune: Rune): RuneInfo =
  runeInfos[rune]
