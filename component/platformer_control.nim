import
  component/[
    animation,
    animation_bank,
    collider,
    movement,
    sprite,
  ],
  input,
  entity,
  event,
  game_system,
  project_config,
  util,
  vec

type
  PlatformerControlObj* = object of Component
    moveSpeed*: float
    acceleration*: float
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
  components = [PlatformerControl, Animation, AnimationBank, Collider, Movement]
  proc updatePlatformerControl*(dt: float, input: InputManager, config: ProjectConfig) =
    let
      control = platformerControl
      raw = vec(input.getAxis(Axis.horizontal),
                input.getAxis(Axis.vertical))
      acc = control.acceleration
      spd = control.moveSpeed
    var vel = movement.vel
    vel.x += raw.x * acc * dt
    let sgn = sign(vel.x).float
    if raw.x != sgn:
      vel.x -= sgn * acc * dt
      if sign(vel.x).float != sgn:
        vel.x = 0.0
    vel.x = clamp(vel.x, -spd, spd)
    movement.vel = vel

    let toPlay =
      if vel.x != 0.0:
        "Run"
      else:
        "Idle"
    animationBank.setAnimation(animation, toPlay)

    if control.dropDownTimer > 0.0:
      control.dropDownTimer -= dt

    if collider.touchingDown and input.isHeld(Input.jump) and raw.y > 0.0:
      control.dropDownTimer = timeToDropDown
    elif collider.touchingDown and input.isPressed(Input.jump):
      movement.vel.y = config.jumpSpeed(control.jumpHeight)
    elif input.isReleased(Input.jump) and (not movement.isFalling(config)):
      movement.vel.y *= jumpReleaseMultiplier

    if control.facingSign == 0:
      control.facingSign = 1.0
    if raw.x != 0:
      control.facingSign = raw.x
    entity.withComponent Sprite, sprite:
      sprite.flipX = control.facingSign < 0
