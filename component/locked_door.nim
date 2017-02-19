import
  component/[
    collider,
  ],
  entity,
  event,
  game_system

type
  KeyObj* = object of ComponentObj
  Key* = ref KeyObj

  KeyCollectionObj* = object of ComponentObj
    numKeys*: int
  KeyCollection* = ref KeyCollectionObj

  LockedDoorObj* = object of ComponentObj
  LockedDoor* = ref LockedDoorObj

defineComponent(Key, @[])
defineComponent(KeyCollection, @[])
defineComponent(LockedDoor, @[])

defineSystem:
  components = [Key, Collider]
  proc updateLocks*(player: Entity) =
    if collider.collisions != nil and player in collider.collisions:
      let keyCollection = player.getComponent(KeyCollection)
      keyCollection.numKeys += 1
      result.add Event(kind: removeEntity, entity: entity)

defineSystem:
  components = [LockedDoor, Collider]
  proc updateLockedDoors*(player: Entity) =
    if collider.collisions != nil and player in collider.collisions:
      let keyCollection = player.getComponent(KeyCollection)
      if keyCollection.numKeys > 0:
        keyCollection.numKeys -= 1
        result.add Event(kind: removeEntity, entity: entity)
