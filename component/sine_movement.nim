import math

import
  component/[
    movement,
  ],
  entity,
  event,
  game_system,
  util,
  vec

type
  SineMovementObj* = object of Component
    speed*: float
    period*: float
    t: float
  SineMovement* = ref SineMovementObj

defineComponent(SineMovement, @[])

defineSystem:
  components = [SineMovement, Movement]
  proc updateSineMovement*(dt: float) =
    let sine = sineMovement
    sine.t += dt
    movement.vel = vec(0.0, sine.speed * sin(sine.t * 2 * PI / sine.period))
