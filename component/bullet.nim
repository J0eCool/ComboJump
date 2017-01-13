import math
from sdl2 import color

import
  component/collider,
  component/health,
  component/movement,
  component/transform,
  component/sprite,
  entity,
  event,
  option,
  targeting,
  util,
  vec

type
  Bullet* = ref object of Component
    liveTime*: float
    timeSinceSpawn*: float
    nextStage*: ShootProc
    onUpdate*: UpdateProc
    dir*: Vec
    speed*: float
    target*: Target
    startPos*: float
    stayOnHit*: bool

  ShootProc* = proc(pos, vel: Vec): Events
  UpdateProc* = proc(entity: Entity, dt: float)

  RepeatShooter* = ref object of Component
    numToRepeat*: int
    toShoot*: ShootProc
    nextStage*: ShootProc
    dir*: Vec
    shootCooldown*: float

proc lifePct*(b: Bullet): float =
  1.0 - b.timeSinceSpawn / b.liveTime

type HomingBullet* = ref object of Component
  turnRate*: float

type FieryBullet* = ref object of Component
  timer*, interval*: float
  liveTime*: float
  size*: float

proc newFieryBullet*(mana: float): FieryBullet =
  FieryBullet(
    timer: 0.0,
    interval: lerp(mana, 0.05, 0.005),
    liveTime: lerp(mana, 0.1, 0.9),
    size: lerp(mana, 0.4, 0.9),
  )
