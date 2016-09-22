import math
import component, vec

type Bullet* = ref object of Component
  damage*: int
  liveTime*: float
  timeLeft*: float
  isSpecial*: bool
  vel*: Vec

proc newBullet*(vel: Vec, damage: int, liveTime: float, isSpecial: bool): Bullet =
  Bullet(
    damage: damage,
    vel: vel,
    isSpecial: isSpecial,
    liveTime: liveTime,
    timeLeft: liveTime,
  )

proc lifePct*(b: Bullet): float =
  b.timeLeft / b.liveTime

type HomingBullet* = ref object of Bullet
  turnRate*: float

proc newHomingBullet*(vel: Vec, damage: int, turnRate: float): Bullet =
  let liveTime = 2.5
  HomingBullet(
    damage: damage,
    vel: vel,
    liveTime: liveTime,
    timeLeft: liveTime,
    turnRate: turnRate.degToRad
  )
