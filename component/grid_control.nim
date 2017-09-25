import
  component/[
    movement,
    transform,
  ],
  input,
  entity,
  event,
  game_system,
  util,
  vec

type
  GridControlObj* = object of Component
    moveSpeed*: float
    dir*: Vec
    followMouse*: bool
  GridControl* = ref GridControlObj

defineComponent(GridControl, @[])

# TODO: fix shakiness when close to mouse
proc mouseDist(transform: Transform, input: InputManager): Vec =
  input.mousePos - transform.globalPos

defineSystem:
  components = [GridControl, Movement, Transform]
  proc gridControl*(dt: float, input: InputManager) =
    if not gridControl.followMouse:
      let raw = vec(input.getAxis(Axis.horizontal),
                    input.getAxis(Axis.vertical)).unit
      movement.vel = raw * gridControl.moveSpeed
      gridControl.dir = raw
    else:
      movement.vel = transform.mouseDist(input)
      movement.vel.length = lerp(movement.vel.length / 100.0, 0.0, gridControl.moveSpeed)
