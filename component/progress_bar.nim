import entity

type ProgressBar* = ref object of Component
  target*: string
  heldTarget*: string
  basePos*: float
  baseSize*: float
  textEntity*: string

proc newProgressBar*(target: string, heldTarget = "", textEntity = ""): ProgressBar =
  new result
  result.target = target
  result.basePos = -1
  result.baseSize = -1
  result.heldTarget = heldTarget
  result.textEntity = textEntity
