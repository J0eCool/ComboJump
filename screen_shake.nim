import
  camera,
  entity,
  event,
  game_system,
  vec

type ScreenShake* = object
  amount: float
  duration: float

proc start*(shake: var ScreenShake, amount, duration: float) =
  shake.amount = amount
  shake.duration = duration

defineSystem:
  priority = -1000
  proc updateScreenShake*(dt: float, camera: var Camera, shake: var ScreenShake) =
    camera.extra = vec()
    if shake.duration > 0.0:
      shake.duration -= dt
      camera.extra += randomVec(0.5, 1.0) * shake.amount
