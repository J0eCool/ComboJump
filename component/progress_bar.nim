import entity

type ProgressBar* = ref object of Component
  target*: string
  heldTarget*: string
  baseSize*: float

proc newProgressBar*(target: string, heldTarget = ""): ProgressBar =
  new result
  result.target = target
  result.baseSize = -1
  result.heldTarget = heldTarget
