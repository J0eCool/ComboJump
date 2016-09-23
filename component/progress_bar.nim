import component

type ProgressBar* = ref object of Component
  target*: string
  baseSize*: float

proc newProgressBar*(target: string): ProgressBar =
  new result
  result.target = target
  result.baseSize = -1