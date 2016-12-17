import math, random
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
  vec,
  util

type ManaScale[T] = object
  base, scale: T
  exp: float

type
  S = ManaScale[float]
  SV = ManaScale[Vec]

proc amt*[T](scale: ManaScale[T], mana: float): T =
  let exp = if scale.exp == 0: 1.0 else: scale.exp
  scale.base + (mana * scale.scale).pow(exp)

type
  RuneKind* = enum
    base
    spread
    homing
    fiery

  Rune* = tuple[kind: RuneKind, cost: float]

  Gun* = object
    damage: ManaScale[float]
    speed: ManaScale[float]
    randSpeed: ManaScale[float]
    numBullets: ManaScale[float]
    angle: ManaScale[float]
    angleOffset: ManaScale[float]
    randAngPer: ManaScale[float]
    size*: ManaScale[Vec]
    liveTime: ManaScale[float]
    randomLiveTime: ManaScale[float]
    extraComponents: seq[Component]
    manaChargeRate*: float
    manaEfficiency: float
    minCost*: float
    nextStage*: ref Gun

  Stage* = tuple[gun: Gun, runes: seq[Rune]]

  SpellDef* = seq[Stage]
  Spell* = Gun

proc createSpell*(def: varargs[Stage]): Spell =
  var guns: seq[ref Gun] = @[]
  for stage in def:
    let
      baseGun = stage.gun
      runes = stage.runes
    var curGun = new(Gun)
    curGun[].deepCopy baseGun

    proc calcFlatCosts(): array[RuneKind, float] =
      result[spread] = 40
      result[homing] = 60
    const flatRuneCosts = calcFlatCosts()
    const constCostRunes: set[RuneKind] = {}
    var rawTotalCost = 0.0
    var totalCost = 0.0
    var extraCost = 0.0
    for r in runes:
      if not (r.kind in constCostRunes):
        rawTotalCost += r.cost
        totalCost += r.cost
      totalCost += flatRuneCosts[r.kind]

    var scaledCosts: array[RuneKind, float]
    for r in runes:
      let
        s = r.cost / rawTotalCost
      assert scaledCosts[r.kind] == 0, "Duplicate runes aren't allowed"
      scaledCosts[r.kind] = s
      extraCost += flatRuneCosts[r.kind] * s

    let s = (extraCost + 100.0) / 100.0
    curGun[].manaEfficiency /= s
    curGun[].manaChargeRate *= sqrt(s)
    curGun[].minCost *= s / curGun[].manaEfficiency

    if curGun[].extraComponents == nil:
      curGun[].extraComponents = @[]
    for r in runes:
      let c = scaledCosts[r.kind]
      case r.kind
      of base:
        curGun[].damage.base += 3 * c
        curGun[].damage.scale += 0.4 * c
      of spread:
        curGun[].numBullets.base += 5 * c
        curGun[].numBullets.scale += 0.2 * c
        curGun[].randSpeed.base += 500 * c
        curGun[].speed.base -= 500 * c
        curGun[].angle.base += 70 * c
        curGun[].angle.scale += 7 * c
        curGun[].liveTime.base -= 1.2 * c
        curGun[].randomLiveTime.base += 0.6 * c
      of homing:
        curGun[].speed.base -= 600 * c
        curGun[].randSpeed.base += 200 * c
        curGun[].angle.base += 150 * c
        curGun[].randAngPer.base += 10 * c
        curGun[].liveTime.scale += 0.06 * c
        curGun[].extraComponents.add HomingBullet(turnRate: 800 * c)
      of fiery:
        curGun[].damage.base += 2 * c
        curGun[].damage.scale += 0.25 * c
        curGun[].speed.base -= 100 * c
        curGun[].speed.scale -= 200 * c
        curGun[].liveTime.scale += 0.05 * c
        curGun[].extraComponents.add newFieryBullet(c)
    guns.add curGun

  let life = 1.0 + (guns.len.float - 1) * 0.5
  for i in 0..<guns.len:
    let gun = guns[i]
    gun[].liveTime.base /= life
    gun[].liveTime.scale /= life
    if i + 1 < guns.len:
      gun[].nextStage = guns[i + 1]
  return guns[0][]

let
  projectileBase* = Gun(
    damage: S(base: 1, scale: 0, exp: 1),
    speed: S(base: 1_000, scale: 300, exp: 0.5),
    numBullets: S(base: 1, scale: 0, exp: 1),
    size: SV(base: vec(12.5), scale: vec(4, 4), exp: 0.5),
    angle: S(base: 0, scale: 0, exp: 0.5),
    liveTime: S(base: 1.5, scale: 0, exp: 1),
    manaChargeRate: 25.0,
    manaEfficiency: 1.0,
    minCost: 5.0,
    )

proc shoot*(gun: Gun, mana: float, shotPoint, dir: Vec): Events;

proc bulletAtDir(gun: Gun, dir, shotPoint: Vec, mana: float): Entity =
  let
    randSpeed = gun.randSpeed.amt(mana)
    speed = gun.speed.amt(mana) + randomNormal(-randSpeed, randSpeed)
    vel = speed * dir
    liveTime = gun.liveTime.amt(mana) + random(-gun.randomLiveTime.amt(mana), gun.randomLiveTime.amt(mana))
  var nextStageProc: ShootProc
  if gun.nextStage != nil:
    nextStageProc = proc(pos, vel: Vec): Events =
      gun.nextStage[].shoot(mana, pos, vel)
  var components: seq[Component] = @[
    Transform(pos: shotPoint, size: gun.size.amt(mana)),
    Movement(vel: vel),
    Collider(layer: Layer.bullet),
    Sprite(color: color(255, 255, 32, 255)),
    Damage(damage: gun.damage.amt(mana).int),
    Bullet(
      liveTime: liveTime,
      nextStage: nextStageProc,
    ),
  ]
  for c in gun.extraComponents:
    components.add(c.copy)

  return newEntity("Bullet", components)

proc shoot*(gun: Gun, mana: float, shotPoint, dir: Vec): seq[Event] =
  let mana = mana * gun.manaEfficiency
  result = @[]
  for i in 0..<gun.numBullets.amt(mana).int:
    var ang =
      if gun.numBullets.amt(mana) > 1:
        (i.float / (gun.numBullets.amt(mana).float - 1) - 0.5) * gun.angle.amt(mana)
      else:
        0
    ang += dir.angle().radToDeg
    ang += random(-gun.randAngPer.amt(mana), gun.randAngPer.amt(mana))
    ang += gun.angleOffset.amt(mana)
    let bullet = gun.bulletAtDir(unitVec(ang.degToRad), shotPoint, mana)
    result.add Event(kind: addEntity, entity: bullet)
