import
  component/limited_quantity,
  entity

type ProgressBar* = ref object of Component
  target*: proc(entities: Entities): LimitedQuantity
  heldTarget*: string
  basePos*: float
  baseSize*: float
  textEntity*: string

defineComponent(ProgressBar)

proc newProgressBar*[T](target: string, heldTarget = "", textEntity = ""): ProgressBar =
  new result
  result.target =
    proc(entities: Entities): LimitedQuantity =
      entities.firstEntityByName(target).getComponent(T)
  result.basePos = -1
  result.baseSize = -1
  result.heldTarget = heldTarget
  result.textEntity = textEntity
