import
  component/[
    movement,
    sprite,
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
    facingSign*: float
  PlatformerControl* = ref PlatformerControlObj

defineComponent(PlatformerControl, @["dropDownTimer"])

const
  jumpReleaseMultiplier = 0.1
  timeToDropDown = 0.25

defineSystem:
  components = [PlatformerControl, Movement]
  proc updatePlatformerControl*(dt: float, input: InputManager) =
    let
      raw = vec(input.getAxis(Axis.horizontal),
                input.getAxis(Axis.vertical))
      dir = vec(raw.x, 0.0)
      spd = platformerControl.moveSpeed
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

    if platformerControl.facingSign == 0:
      platformerControl.facingSign = 1.0
    if raw.x != 0:
      platformerControl.facingSign = raw.x
      let sprite = entity.getComponent(Sprite)
      if sprite != nil:
        sprite.flipX = raw.x < 0
