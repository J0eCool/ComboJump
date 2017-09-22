import
  component/[
    movement,
    transform,
  ],
  input,
  entity,
  event,
  game_system,
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

proc getRawInput(grid: GridControl, transform: Transform, input: InputManager): Vec =
  if not grid.followMouse:
    vec(input.getAxis(Axis.horizontal),
        input.getAxis(Axis.vertical)).unit
  else:
    mouseDist(transform, input).unit

defineSystem:
  components = [GridControl, Movement, Transform]
  proc gridControl*(dt: float, input: InputManager) =
    let
      raw = gridControl.getRawInput(transform, input)
      spd = gridControl.moveSpeed
      vel = raw * spd
    movement.vel = vel
    gridControl.dir = raw
