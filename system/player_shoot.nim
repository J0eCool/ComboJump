import math, random, sdl2

import
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


const
  speed = 1500.0
  specialNumBullets = 6
  specialAngle = 40.0
  specialRandAngPer = 5.0

proc playerShoot*(entities: seq[Entity]): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    PlayerControl, p,
    Mana, m,
    Transform, t,
  ]):
    proc bulletAtDir(dir: Vec, isSpecial = false, isHoming = false, size = vec(20, 20)): Entity =
      let
        shotPoint = t.rect.center + vec(t.size.x * 0.5 * p.facing.float - size.x / 2, -size.y / 2)
        bullet = if not isHoming:
                  newBullet(
                    damage=1,
                    liveTime= if isSpecial: random(0.3, 0.6) else: 1.5,
                    isSpecial=isSpecial,
                    vel=speed * dir,
                  )
                 else:
                  newHomingBullet(
                    damage=1,
                    vel=0.5 * speed * dir,
                    turnRate=random(350.0, 500.0),
                  )

      newEntity("Bullet", [
        Transform(pos: shotPoint, size: size),
        Movement(),
        Collider(layer: Layer.bullet),
        Sprite(color: color(255, 255, 32, 255)),
        bullet,
      ])
    proc trySpend(cost: int): bool =
      if m.cur >= cost.float:
        m.cur -= cost.float
        return true
      return false
    if p.spell1Pressed and trySpend(5):
      result.add bulletAtDir(dir=vec(p.facing, 0))
    if p.spell2Pressed and trySpend(18):
      for i in 0..<specialNumBullets div 2:
        var ang = (2.0 * i.float / (specialNumBullets.float / 2 - 1) - 1.0) * specialAngle / 2
        if p.facing != 1:
          ang += 180.0
        ang += random(-specialRandAngPer, specialRandAngPer)
        result.add bulletAtDir(dir=unitVec(ang.degToRad), isSpecial=true)

        ang = random(random(-specialAngle, 0.0), random(0.0, specialAngle))
        if p.facing != 1:
          ang += 180.0
        result.add bulletAtDir(dir=unitVec(ang.degToRad)*random(0.8, 1.2), isSpecial=true)
    if p.spell3Pressed and trySpend(40):
      for i in 0..<specialNumBullets div 2:
        var ang = (2.0 * i.float / (specialNumBullets.float / 2 - 1) - 1.0) * specialAngle / 2
        if p.facing == 1:
          ang += 180.0
        ang += random(-specialRandAngPer, specialRandAngPer)
        result.add bulletAtDir(dir=unitVec(ang.degToRad), isHoming=true)

        ang = random(random(-specialAngle, 0.0), random(0.0, specialAngle))
        if p.facing == 1:
          ang += 180.0
        result.add bulletAtDir(dir=unitVec(ang.degToRad)*random(0.8, 1.2), isHoming=true)
