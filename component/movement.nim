import
  math

import
  entity,
  util,
  vec

type Movement* = ref object of Component
  vel*: Vec
  usesGravity*: bool
  onGround*: bool

defineComponent(Movement)

const gravity* = 2_100.0
proc jumpSpeed*(height: float): float =
  -sign(gravity).float * sqrt(2 * height * abs(gravity))

