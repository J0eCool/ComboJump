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
    enemyBullet
    playerTrigger

  Collider* = ref object of Component
    layer*: Layer
    collisions*: seq[Entity]
    collisionBlacklist*: seq[Entity]

proc initLayerMask(): array[Layer, set[Layer]] =
  result[player] = { floor, enemy, enemyBullet }
  result[enemy] = { floor, player, bullet }
  result[bullet] = { enemy }
  result[enemyBullet] = { player }
  result[playerTrigger] = { player }
const layerMask = initLayerMask()

proc canCollideWith*(obj, other: Layer): bool =
  layerMask[obj].contains(other)
