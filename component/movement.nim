import
  math

import
  entity,
  project_config,
  util,
  vec

type
  MovementObj* = object of ComponentObj
    vel*: Vec
    usesGravity*: bool
    canDropDown*: bool
  Movement* = ref MovementObj

defineComponent(Movement, @[])

proc jumpSpeed*(config: ProjectConfig, height: float): float =
  -sign(config.gravity).float * sqrt(2 * height * abs(config.gravity))

proc isFalling*(movement: Movement, config: ProjectConfig): bool =
  movement.vel.y * config.gravity > 0
