import
  component/clickable,
  component/mana,
  component/player_control,
  entity,
  event,
  input,
  rect

const spells = @[Input.spell1, Input.spell2, Input.spell3]

proc playerInput*(entities: seq[Entity], input: InputManager): Events =
  entities.forComponents e, [
    PlayerControl, p,
    PlayerShooting, ps,
  ]:
    p.jumpPressed = input.isPressed(Input.jump)
    p.jumpReleased = input.isReleased(Input.jump)

    if ps.heldSpell != 0:
      ps.isSpellHeld = input.isHeld spells[ps.heldSpell - 1]
    else:
      for i in 0..<spells.len:
        if input.isPressed spells[i]:
          ps.heldSpell = i + 1
          ps.isSpellHeld = true
          break

    var dir = 0
    if not ps.isCasting:
      if input.isHeld(Input.left):
        dir -= 1
      if input.isHeld(Input.right):
        dir += 1
    p.moveDir = dir

    if p.moveDir != 0:
      p.facing = p.moveDir
    if p.facing == 0:
      p.facing = 1

proc clickPlayer*(entities: seq[Entity]): Events =
  entities.forComponents e, [
    Mana, m,
    Clickable, c,
  ]:
    if c.held:
      echo "Holding player with " & $m.cur & " mana"
      m.cur += 0.5
