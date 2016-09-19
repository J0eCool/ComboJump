import input, component

type PlayerControl* = ref object of Component
  moveDir*: int
  jumpHeld*: bool
  jumpPressed*: bool
