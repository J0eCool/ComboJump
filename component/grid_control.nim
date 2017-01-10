import
  component/movement,
  input,
  entity,
  event,
  system,
  vec

type GridControl* = ref object of Component
  moveSpeed*: float
  dir*: Vec

defineSystem:
  components = [GridControl, Movement]
  proc gridControl*(input: InputManager) =
    let raw = vec(input.getAxis(Axis.horizontal),
                  input.getAxis(Axis.vertical))
    movement.vel = raw * gridControl.moveSpeed
    gridControl.dir = raw.unit
