import input, component

type PlayerControl* = ref object of Component
  moveDir*: int
  jumpReleased*: bool
  jumpPressed*: bool
