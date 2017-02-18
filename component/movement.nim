import
  math

import
  entity,
  util,
  vec

type
  MovementObj* = object of ComponentObj
    vel*: Vec
    usesGravity*: bool
    onGround*: bool
  Movement* = ref MovementObj

defineComponent(Movement)

const gravity* = 2_100.0
proc jumpSpeed*(height: float): float =
  -sign(gravity).float * sqrt(2 * height * abs(gravity))

