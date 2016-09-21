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

type HomingBullet* = ref object of Bullet
  accel*: float

proc newHomingBullet*(vel: Vec, damage: int): Bullet =
  let liveTime = 2.5
  HomingBullet(
    damage: damage,
    vel: vel,
    liveTime: liveTime,
    timeLeft: liveTime,
    accel: 3_500.0
  )
