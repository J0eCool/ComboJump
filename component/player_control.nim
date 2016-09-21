import input, component

type PlayerControl* = ref object of Component
  facing*: int
  moveDir*: int
  jumpReleased*: bool
  jumpPressed*: bool
  spell1Pressed*: bool
  spell2Pressed*: bool
  spell3Pressed*: bool
