import
  entity,
  vec

type
  Layer* = enum
    none
    floor
    player
    enemy
    bullet
    playerTrigger

  Collider* = ref object of Component
    layer*: Layer
    collisions*: seq[Entity]

proc initLayerMask(): array[Layer, set[Layer]] =
  result[player] = { floor, enemy }
  result[enemy] = { floor, player, bullet }
  result[bullet] = { enemy }
  result[playerTrigger] = { player }
const layerMask = initLayerMask()

proc canCollideWith*(obj, other: Layer): bool =
  layerMask[obj].contains(other)
