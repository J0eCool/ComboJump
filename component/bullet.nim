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
    randomNum*: float

  ShootProc* = proc(pos, vel: Vec): Events
  UpdateProc* = proc(entity: Entity, dt: float)

  RepeatShooter* = ref object of Component
    numToRepeat*: int
    toShoot*: ShootProc
    nextStage*: ShootProc
    dir*: Vec
    shootCooldown*: float

defineComponent(Bullet)
defineComponent(RepeatShooter)

proc lifePct*(b: Bullet): float =
  1.0 - b.timeSinceSpawn / b.liveTime
