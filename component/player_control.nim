import input, component

type PlayerControl* = ref object of Component
  facing*: int
  moveDir*: int
  jumpReleased*: bool
  jumpPressed*: bool
  heldSpell*: int
  spellReleased*: bool
  heldMana*: float
