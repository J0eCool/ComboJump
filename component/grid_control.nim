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
  proc gridControl*(input: InputManager) =
    entities.forComponents e, [
      GridControl, c,
      Movement, m,
    ]:
      let raw = vec(input.getAxis(Axis.horizontal),
                    input.getAxis(Axis.vertical))
      m.vel = raw * c.moveSpeed
      c.dir = raw.unit
