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
  util,
  vec

type
  Bullet* = ref object of Component
    liveTime*: float
    timeLeft*: float
    nextStage*: ShootProc
    onUpdate*: UpdateProc

  ShootProc* = proc(pos, vel: Vec): Events
  UpdateProc* = proc(entity: Entity, dt: float)

proc newBullet*(liveTime: float, nextStage: ShootProc = nil, onUpdate: UpdateProc = nil): Bullet =
  Bullet(
    liveTime: liveTime,
    timeLeft: liveTime,
    nextStage: nextStage,
    onUpdate: onUpdate,
  )

proc lifePct*(b: Bullet): float =
  b.timeLeft / b.liveTime

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
