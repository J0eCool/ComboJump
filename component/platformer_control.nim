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

type
  PlatformerControlObj* = object of Component
    moveSpeed*: float
    jumpHeight*: float
  PlatformerControl* = ref PlatformerControlObj

defineComponent(PlatformerControl, @[])

const
  castingMoveSpeedMultiplier = 0.3
  jumpReleaseMultiplier = 0.25

defineSystem:
  components = [PlatformerControl, TargetShooter, Movement]
  proc updatePlatformerControl*(input: InputManager) =
    let
      raw = vec(input.getAxis(Axis.horizontal),
                input.getAxis(Axis.vertical))
      dir = vec(raw.x, 0.0)
      mult =
        if targetShooter.isCasting:
          castingMoveSpeedMultiplier
        else:
          1.0
      spd = platformerControl.moveSpeed * mult
      vel = dir * spd
    movement.vel.x = vel.x

    if input.isPressed(Input.jump):
      movement.vel.y = jumpSpeed(platformerControl.jumpHeight)
    let isJumping = movement.vel.y * gravity < 0.0
    if input.isReleased(Input.jump) and isJumping:
      movement.vel.y *= jumpReleaseMultiplier
