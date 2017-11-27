import
  component/[
    collider,
    movement,
    sprite,
  ],
  input,
  entity,
  event,
  game_system,
  util,
  vec

type
  PlatformerControlObj* = object of Component
    moveSpeed*: float
    jumpHeight*: float
    dropDownTimer: float
    facingSign*: float
  PlatformerControl* = ref PlatformerControlObj

defineComponent(PlatformerControl, @[
  "dropDownTimer",
])

const
  jumpReleaseMultiplier = 0.1
  timeToDropDown = 0.25

defineSystem:
  components = [PlatformerControl, Collider, Movement]
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

    if collider.touchingDown and input.isHeld(Input.jump) and raw.y > 0.0:
      platformerControl.dropDownTimer = timeToDropDown
    elif collider.touchingDown and input.isPressed(Input.jump):
      movement.vel.y = jumpSpeed(platformerControl.jumpHeight)
    elif input.isReleased(Input.jump) and (not movement.isFalling):
      movement.vel.y *= jumpReleaseMultiplier

    if platformerControl.facingSign == 0:
      platformerControl.facingSign = 1.0
    if raw.x != 0:
      platformerControl.facingSign = raw.x
    entity.withComponent Sprite, sprite:
      sprite.flipX = platformerControl.facingSign < 0
