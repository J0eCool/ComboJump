import component/player_control,
       entity,
       input

proc playerInput*(entities: seq[Entity], input: InputManager) =
  forComponents(entities, e, [PlayerControl, p]):
    p.jumpPressed = input.isPressed(Input.jump)
    p.jumpReleased = input.isReleased(Input.jump)
    p.spell1Pressed = input.isPressed(Input.spell1)
    p.spell2Pressed = input.isPressed(Input.spell2)
    p.spell3Pressed = input.isPressed(Input.spell3)

    var dir = 0
    if input.isHeld(Input.left):
      dir -= 1
    if input.isHeld(Input.right):
      dir += 1
    p.moveDir = dir

    if p.moveDir != 0:
      p.facing = p.moveDir
    if p.facing == 0:
      p.facing = 1
