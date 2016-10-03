import input, component

type PlayerControl* = ref object of Component
  facing*: int
  moveDir*: int
  jumpReleased*: bool
  jumpPressed*: bool
  heldSpell*: int
  isSpellHeld*: bool

proc isCasting*(control: PlayerControl): bool =
  control.heldSpell != 0
