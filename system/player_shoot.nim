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

let
  normal = Gun(
    damage: S(base: 3, scale: 0.1, exp: 1),
    speed: S(base: 1_000, scale: 500, exp: 0.65),
    numBullets: S(base: 1, scale: 0, exp: 1),
    size: SV(base: vec(20), scale: vec(6.0, 1.5), exp: 0.65),
    liveTime: S(base: 1.5, scale: 0, exp: 1),
    )
  spread = Gun(
    damage: S(base: 1, scale: 0.04, exp: 1),
    speed: S(base: 950, scale: 10, exp: 1),
    size: SV(base: vec(15), scale: vec(1.5), exp: 0.65),
    numBullets: S(base: 5, scale: 0.12, exp: 1),
    angle: S(base: 40, scale: 1.5, exp: 1),
    liveTime: S(base: 0.45, scale: 0, exp: 1),
    randomLiveTime: S(base: 0.15, scale: 0, exp: 1),
    extraComponents: C(SpreadBullet()),
    )
  homing = Gun(
    damage: S(base: 1, scale: 0, exp: 1),
    speed: S(base: 750, scale: 0, exp: 1),
    size: SV(base: vec(25), scale: vec(0), exp: 1),
    numBullets: S(base: 6, scale: 0, exp: 1),
    angle: S(base: 90, scale: 0, exp: 1),
    angleOffset: S(base: 180, scale: 0, exp: 1),
    liveTime: S(base: 2.5, scale: 0, exp: 1),
    extraComponents: C(HomingBullet()),
    )

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
      p.heldMana += 75.0 * dt
      p.heldMana = min(p.heldMana, m.cur)
    if p.spellReleased:
      if p.heldSpell == 1 and trySpend(p.heldMana):
        result = normal.shoot(p.heldMana)
      elif p.heldSpell == 2 and trySpend(p.heldMana):
        result = spread.shoot(p.heldMana)
      elif p.heldSpell == 3 and trySpend(p.heldMana):
        result = homing.shoot(p.heldMana)
      p.heldMana = 0
