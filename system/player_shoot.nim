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


type Gun* = object
  damage: int
  speed: float
  numBullets: int
  angle: float
  angleOffset: float
  randAngPer: float
  size: Vec
  liveTime: float
  randomLiveTime: float
  extraComponents: seq[Component]

let
  normal = Gun(
    damage: 3,
    speed: 1_500,
    numBullets: 1,
    size: vec(20),
    liveTime: 1.5,
    )
  spread = Gun(
    damage: 1,
    speed: 950,
    size: vec(15),
    numBullets: 6,
    angle: 40,
    liveTime: 0.45,
    randomLiveTime: 0.15,
    extraComponents: C(SpreadBullet()),
    )
  homing = Gun(
    damage: 1,
    speed: 750,
    size: vec(25),
    numBullets: 6,
    angle: 90,
    angleOffset: 180,
    liveTime: 2.5,
    extraComponents: C(HomingBullet()),
    )

proc playerShoot*(entities: seq[Entity]): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    PlayerControl, p,
    Mana, m,
    Transform, t,
  ]):
    proc bulletAtDir(gun: Gun, dir: Vec): Entity =
      let
        shotPoint = t.rect.center + vec(t.size.x * 0.5 * p.facing.float, 0) - gun.size / 2
        vel = gun.speed * dir
        liveTime = gun.liveTime + random(-gun.randomLiveTime, gun.randomLiveTime)
      var components: seq[Component] = @[
        Transform(pos: shotPoint, size: gun.size),
        Movement(vel: vel),
        Collider(layer: Layer.bullet),
        Sprite(color: color(255, 255, 32, 255)),
        newBullet(
          damage=gun.damage,
          liveTime=liveTime,
        ),
      ]
      for c in gun.extraComponents:
        components.add(c.copy)

      return newEntity("Bullet", components)

    proc trySpend(cost: int): bool =
      if m.cur >= cost.float:
        m.cur -= cost.float
        return true
      return false

    proc shoot(gun: Gun): seq[Entity] =
      result = @[]
      for i in 0..<gun.numBullets:
        var ang =
          if gun.numBullets > 1:
            (i.float / (gun.numBullets.float - 1) - 0.5) * gun.angle
          else:
            0
        if p.facing != 1:
          ang += 180.0
        ang += random(-gun.randAngPer, gun.randAngPer)
        ang += gun.angleOffset
        result.add gun.bulletAtDir(unitVec(ang.degToRad))

    if p.spell1Pressed and trySpend(5):
      result = normal.shoot()
    elif p.spell2Pressed and trySpend(18):
      result = spread.shoot()
    elif p.spell3Pressed and trySpend(40):
      result = homing.shoot()
