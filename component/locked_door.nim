import
  component/[
    collider,
  ],
  entity,
  event,
  game_system

type
  Key* = ref object of Component
  LockedDoor* = ref object of Component
  LockCollection* = ref object of Component
    numKeys: int

defineSystem:
  components = [Key, Collider]
  proc updateLocks*(player: Entity) =
    if collider.collisions != nil and player in collider.collisions:
      let lockCollection = player.getComponent(LockCollection)
      lockCollection.numKeys += 1
      result.add Event(kind: removeEntity, entity: entity)

defineSystem:
  components = [LockedDoor, Collider]
  proc updateLockedDoors*(player: Entity) =
    if collider.collisions != nil and player in collider.collisions:
      let lockCollection = player.getComponent(LockCollection)
      if lockCollection.numKeys > 0:
        lockCollection.numKeys -= 1
        result.add Event(kind: removeEntity, entity: entity)
