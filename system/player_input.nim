import
  component/player_control,
  entity,
  event,
  input

const spells = @[Input.spell1, Input.spell2, Input.spell3]

proc playerInput*(entities: seq[Entity], input: InputManager): Events =
  forComponents(entities, e, [PlayerControl, p]):
    p.jumpPressed = input.isPressed(Input.jump)
    p.jumpReleased = input.isReleased(Input.jump)

    if p.spellReleased:
      p.spellReleased = false
      p.heldSpell = 0
    if p.heldSpell != 0:
      if input.isReleased spells[p.heldSpell - 1]:
        p.spellReleased = true
    else:
      for i in 0..<spells.len:
        if input.isPressed spells[i]:
          p.heldSpell = i + 1
          break

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
