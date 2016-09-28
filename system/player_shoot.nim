import math, random, sdl2

import
  component/component,
  component/bullet,
  component/collider,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  entity,
  rect,
  vec,
  util

type ManaScale[T] = object
  base, scale: T
  exp: float

type
  S = ManaScale[float]
  SV = ManaScale[Vec]

proc amt[T](scale: ManaScale[T], mana: float): T =
  let exp = if scale.exp == 0: 1.0 else: scale.exp
  scale.base + (mana * scale.scale).pow(exp)

type Gun* = object
  damage: ManaScale[float]
  speed: ManaScale[float]
  numBullets: ManaScale[float]
  angle: ManaScale[float]
  angleOffset: ManaScale[float]
  randAngPer: ManaScale[float]
  size: ManaScale[Vec]
  liveTime: ManaScale[float]
  randomLiveTime: ManaScale[float]
  extraComponents: seq[Component]

type
  RuneKind* = enum
    damage
    spread
    homing

  Rune* = tuple[kind: RuneKind, cost: float]


proc createSpell*(baseGun: Gun, runes: varargs[Rune]): Gun =
  const constCostRunes: set[RuneKind] = {}
  var totalCost = 0.0
  for r in runes:
    if not (r.kind in constCostRunes):
      totalCost += r.cost
  var scaledCosts: array[RuneKind, float]
  for r in runes:
    scaledCosts[r.kind] = r.cost / totalCost

  result.deepCopy baseGun
  if result.extraComponents == nil:
    result.extraComponents = @[]
  for r in runes:
    let c = scaledCosts[r.kind]
    case r.kind
    of damage:
      result.damage.scale += c * 0.15
    of spread:
      result.numBullets.base += 4 * c
      result.numBullets.scale += 0.1 * c
      result.speed.base -= 300 * c
      result.angle.base += 60 * c
      result.angle.scale += 5 * c
      result.randomLiveTime.base += 0.7 * c
    of homing:
      result.speed.base -= 400 * c
      result.angle.base += 90 * c
      result.randAngPer.base += 4 * c
      result.extraComponents.add HomingBullet(turnRate: 600 * c)
      discard

let
  projectileBase = Gun(
    damage: S(base: 3, scale: 0.1, exp: 1),
    speed: S(base: 1_000, scale: 500, exp: 0.5),
    numBullets: S(base: 1, scale: 0, exp: 1),
    size: SV(base: vec(15), scale: vec(3, 3), exp: 0.5),
    angle: S(base: 0, scale: 0, exp: 0.5),
    liveTime: S(base: 1.5, scale: 0, exp: 1),
    )
  
  normalSpell = projectileBase.createSpell((damage, 100.0))
  spreadSpell = projectileBase.createSpell((damage, 40.0), (spread, 60.0))
  homingSpell = projectileBase.createSpell((damage, 20.0), (spread, 40.0), (homing, 40.0))

proc playerShoot*(entities: seq[Entity], dt: float): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    PlayerControl, p,
    Mana, m,
    Transform, t,
  ]):
    proc bulletAtDir(gun: Gun, dir: Vec, mana: float): Entity =
      let
        shotPoint = t.rect.center + vec(t.size.x * 0.5 * p.facing.float, 0) - gun.size.amt(mana) / 2
        vel = gun.speed.amt(mana) * dir
        liveTime = gun.liveTime.amt(mana) + random(-gun.randomLiveTime.amt(mana), gun.randomLiveTime.amt(mana))
      var components: seq[Component] = @[
        Transform(pos: shotPoint, size: gun.size.amt(mana)),
        Movement(vel: vel),
        Collider(layer: Layer.bullet),
        Sprite(color: color(255, 255, 32, 255)),
        newBullet(
          damage=gun.damage.amt(mana).int,
          liveTime=liveTime,
        ),
      ]
      for c in gun.extraComponents:
        components.add(c.copy)

      return newEntity("Bullet", components)

    proc trySpend(cost: float): bool =
      if m.cur >= cost:
        m.cur -= cost
        return true
      return false

    proc shoot(gun: Gun, mana: float): seq[Entity] =
      result = @[]
      for i in 0..<gun.numBullets.amt(mana).int:
        var ang =
          if gun.numBullets.amt(mana) > 1:
            (i.float / (gun.numBullets.amt(mana).float - 1) - 0.5) * gun.angle.amt(mana)
          else:
            0
        if p.facing != 1:
          ang += 180.0
        ang += random(-gun.randAngPer.amt(mana), gun.randAngPer.amt(mana))
        ang += gun.angleOffset.amt(mana)
        result.add gun.bulletAtDir(unitVec(ang.degToRad), mana)

    if p.heldSpell != 0:
      m.held += 75.0 * dt
      m.held = min(m.held, m.cur)
    if p.spellReleased:
      if p.heldSpell == 1 and trySpend(m.held):
        result = normalSpell.shoot(m.held)
      elif p.heldSpell == 2 and trySpend(m.held):
        result = spreadSpell.shoot(m.held)
      elif p.heldSpell == 3 and trySpend(m.held):
        result = homingSpell.shoot(m.held)
      m.held = 0
