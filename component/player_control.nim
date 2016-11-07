import
  input,
  entity,
  gun,
  vec,
  util

type
  PlayerControl* = ref object of Component
    facing*: int
    moveDir*: int
    jumpReleased*: bool
    jumpPressed*: bool

  PlayerShooting* = ref object of Component
    spells*: array[3, Spell]
    heldSpell*: int
    isSpellHeld*: bool

proc facingDir*(control: PlayerControl): Vec =
  vec(control.facing.sign(), 0)

proc isCasting*(shooting: PlayerShooting): bool =
  shooting.heldSpell != 0
