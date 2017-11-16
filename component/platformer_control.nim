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
    wallJumpTimer: float
  PlatformerControl* = ref PlatformerControlObj

defineComponent(PlatformerControl, @[
  "dropDownTimer",
  "wallJumpTimer",
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
    platformerControl.wallJumpTimer -= dt
    if collider.touchingDown:
      platformerControl.wallJumpTimer = 0.0
    if platformerControl.wallJumpTimer <= 0.0:
      movement.vel.x = vel.x

    if platformerControl.dropDownTimer > 0.0:
      platformerControl.dropDownTimer -= dt

    if collider.touchingDown and input.isHeld(Input.jump) and raw.y > 0.0:
      platformerControl.dropDownTimer = timeToDropDown
    elif collider.touchingDown and input.isPressed(Input.jump):
      movement.vel.y = jumpSpeed(platformerControl.jumpHeight)
    elif collider.touchingLeft and input.isPressed(Input.jump):
      # TODO: this is kinda hacky fix it proper later
      movement.vel = vec(spd * 1.25, jumpSpeed(platformerControl.jumpHeight * 0.75))
      platformerControl.wallJumpTimer = 0.5
    elif collider.touchingRight and input.isPressed(Input.jump):
      movement.vel = vec(-spd * 1.25, jumpSpeed(platformerControl.jumpHeight * 0.75))
      platformerControl.wallJumpTimer = 0.5
    elif input.isReleased(Input.jump) and (not movement.isFalling):
      movement.vel.y *= jumpReleaseMultiplier

    if platformerControl.facingSign == 0:
      platformerControl.facingSign = 1.0
    if raw.x != 0:
      platformerControl.facingSign = raw.x
    if platformerControl.wallJumpTimer > 0.0:
      platformerControl.facingSign = sign(movement.vel.x).float
    let sprite = entity.getComponent(Sprite)
    if sprite != nil:
      sprite.flipX = platformerControl.facingSign < 0
