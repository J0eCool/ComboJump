import math
import component, vec

type Bullet* = ref object of Component
  damage*: int
  liveTime*: float
  timeLeft*: float

proc newBullet*(damage: int, liveTime: float): Bullet =
  Bullet(
    damage: damage,
    liveTime: liveTime,
    timeLeft: liveTime,
  )

proc lifePct*(b: Bullet): float =
  b.timeLeft / b.liveTime

type HomingBullet* = ref object of Component
  turnRate*: float
