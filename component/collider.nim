import tables

import
  entity,
  jsonparse,
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

  ColliderObj* = object of ComponentObj
    layer*: Layer
    collisions*: seq[Entity]
    collisionBlacklist: seq[Entity]
    bufferedCollisions*: seq[Entity]
  Collider* = ref ColliderObj

proc toJSON*(collider: ColliderObj): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["layer"] = collider.layer.toJSON()
proc fromJSON*(collider: var ColliderObj, json: JSON) =
  assert json.kind == jsObject
  collider.layer.fromJSON(json.obj["layer"])

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
