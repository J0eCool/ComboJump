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
    collisionBlacklist: seq[Entity]
    bufferedCollisions*: seq[Entity]

defineComponent(Collider)

proc initLayerMask(): array[Layer, set[Layer]] =
  result[player] = { floor, enemy, enemyBullet }
  result[enemy] = { floor, player, bullet }
  result[bullet] = { enemy }
  result[enemyBullet] = { player }
  result[playerTrigger] = { player }
const layerMask = initLayerMask()

proc canCollideWith*(obj, other: Layer): bool =
  layerMask[obj].contains(other)

proc isBlacklisted*(collider: Collider, entity: Entity): bool =
  collider.collisionBlacklist != nil and entity in collider.collisionBlacklist

proc addToBlacklist*(collider: Collider, entity: Entity) =
  if collider.collisionBlacklist == nil:
    collider.collisionBlacklist = @[entity]
  else:
    collider.collisionBlacklist.add entity

proc bufferedAdd*(collider: Collider, entity: Entity) =
  collider.bufferedCollisions.safeAdd entity
