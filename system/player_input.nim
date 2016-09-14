import ../component/player_control,
       ../entity,
       ../input

proc playerInput*(entities: seq[Entity], input: InputManager) =
  for e in entities:
    let p = e.getComponent(PlayerControl)
    if p != nil:
      p.jumpPressed = false
      if input.isPressed(Input.jump):
        p.jumpPressed = true
        p.jumpStarted = true
      p.jumpHeld = input.isHeld(Input.jump)

      var dir = 0
      if input.isHeld(Input.left):
        dir -= 1
      if input.isHeld(Input.right):
        dir += 1
      p.moveDir = dir
