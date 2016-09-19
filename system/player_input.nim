import component/player_control,
       entity,
       input

proc playerInput*(entities: seq[Entity], input: InputManager) =
  forComponents(entities, e, [PlayerControl, p]):
    p.jumpPressed = input.isPressed(Input.jump)
    p.jumpReleased = input.isReleased(Input.jump)

    var dir = 0
    if input.isHeld(Input.left):
      dir -= 1
    if input.isHeld(Input.right):
      dir += 1
    p.moveDir = dir
