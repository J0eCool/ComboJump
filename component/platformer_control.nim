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
    dropDownTimer: float
  PlatformerControl* = ref PlatformerControlObj

defineComponent(PlatformerControl, @["dropDownTimer"])

const
  castingMoveSpeedMultiplier = 0.3
  jumpReleaseMultiplier = 0.25
  timeToDropDown = 0.25

defineSystem:
  components = [PlatformerControl, TargetShooter, Movement]
  proc updatePlatformerControl*(dt: float, input: InputManager) =
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

    if platformerControl.dropDownTimer > 0.0:
      platformerControl.dropDownTimer -= dt

    if movement.onGround and input.isHeld(Input.jump) and raw.y > 0.0:
      platformerControl.dropDownTimer = timeToDropDown
    elif input.isPressed(Input.jump):
      movement.vel.y = jumpSpeed(platformerControl.jumpHeight)
    elif input.isReleased(Input.jump) and (not movement.isFalling):
      movement.vel.y *= jumpReleaseMultiplier

    movement.canDropDown = platformerControl.dropDownTimer > 0.0
