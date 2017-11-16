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
    canDropDown*: bool
  Movement* = ref MovementObj

defineComponent(Movement, @[])

const
  gravity* = 2_100.0
  gravitySign* = gravity.sign.float
proc jumpSpeed*(height: float): float =
  -gravitySign * sqrt(2 * height * abs(gravity))

proc isFalling*(movement: Movement): bool =
  movement.vel.y * gravity > 0
