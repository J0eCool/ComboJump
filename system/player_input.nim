import component/player_control,
       entity,
       input

proc playerInput*(entities: seq[Entity], input: InputManager) =
  forComponents(entities, e, [PlayerControl, p]):
    p.jumpPressed = false
    if input.isPressed(Input.jump):
      p.jumpPressed = true
    p.jumpHeld = input.isHeld(Input.jump)

    var dir = 0
    if input.isHeld(Input.left):
      dir -= 1
    if input.isHeld(Input.right):
      dir += 1
    p.moveDir = dir
