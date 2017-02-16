import
  component/[
    movement,
    target_shooter,
  ],
  input,
  entity,
  event,
  game_system,
  vec

type GridControl* = ref object of Component
  moveSpeed*: float
  dir*: Vec

defineComponent(GridControl)

const castingMoveSpeedMultiplier = 0.3

defineSystem:
  components = [GridControl, TargetShooter, Movement]
  proc gridControl*(input: InputManager) =
    let
      raw = vec(input.getAxis(Axis.horizontal),
                input.getAxis(Axis.vertical))
      mult =
        if targetShooter.isCasting:
          castingMoveSpeedMultiplier
        else:
          1.0
      spd = gridControl.moveSpeed * mult
    movement.vel = raw * spd
    gridControl.dir = raw.unit
