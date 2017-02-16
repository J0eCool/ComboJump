import
  component/[
    collider,
  ],
  entity,
  event,
  game_system

type
  Key* = ref object of Component
  KeyCollection* = ref object of Component
    numKeys*: int
  LockedDoor* = ref object of Component

defineComponent(Key)
defineComponent(KeyCollection)
defineComponent(LockedDoor)

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
