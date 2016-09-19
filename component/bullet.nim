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
