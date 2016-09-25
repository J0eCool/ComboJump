import math
import component, vec

type Bullet* = ref object of Component
  damage*: int
  liveTime*: float
  timeLeft*: float
  isSpecial*: bool
  baseVel*: Vec

proc newBullet*(damage: int, liveTime: float, isSpecial: bool): Bullet =
  Bullet(
    damage: damage,
    isSpecial: isSpecial,
    liveTime: liveTime,
    timeLeft: liveTime,
  )

proc lifePct*(b: Bullet): float =
  b.timeLeft / b.liveTime

type HomingBullet* = ref object of Component
  turnRate*: float
