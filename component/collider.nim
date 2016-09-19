import
  component/component,
  entity,
  vec

type
  Layer* = enum
    floor
    player
    enemy
    bullet

  Collider* = ref object of Component
    layer*: Layer
    collisions*: seq[Entity]

proc initLayerMask(): array[Layer, set[Layer]] =
  result[player] = { floor, enemy }
  result[enemy] = { floor, player, bullet }
const layerMask = initLayerMask()

proc canCollideWith*(obj, other: Layer): bool =
  layerMask[obj].contains(other)
