import tables

import
  entity,
  jsonparse,
  vec

type
  Layer* = enum
    none
    floor
    oneWayPlatform
    player
    enemy
    bullet
    enemyBullet
    playerTrigger

  ColliderObj* = object of ComponentObj
    layer*: Layer
    collisions*: seq[Entity]
    collisionBlacklist: seq[Entity]
    bufferedCollisions*: seq[Entity]
    touchingDown*: bool
    touchingRight*: bool
    touchingLeft*: bool
  Collider* = ref ColliderObj

defineComponent(Collider, @[
  "collisions",
  "collisionBlacklist",
  "bufferedCollisions",
  "touchingDown",
  "touchingRight",
  "touchingLeft",
])

const layerMask: array[Layer, set[Layer]] = [
  none: {},
  floor: {},
  oneWayPlatform: {},
  player: { floor, oneWayPlatform, enemy, enemyBullet },
  enemy: { floor, oneWayPlatform, player, bullet },
  bullet: { floor, enemy },
  enemyBullet: { floor, player },
  playerTrigger: { player },
]

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
