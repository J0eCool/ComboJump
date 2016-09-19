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

const layerMask: array[Layer, set[Layer]] = [
  {},
  { floor, enemy },
  { floor, player, bullet },
  {},
]

proc canCollideWith*(obj, other: Layer): bool =
  layerMask[obj].contains(other)
