import
  component/[
    collider,
    transform,
  ],
  camera,
  entity,
  event,
  game_system,
  vec

type RoomCameraTarget* = ref object of Component

defineComponent(RoomCameraTarget)

defineSystem:
  priority = -10
  components = [RoomCameraTarget, Collider, Transform]
  proc updateRoomCamera*(player: Entity, camera: var Camera) =
    if player in collider.collisions:
      camera.pos = camera.screenSize / 2 - transform.globalPos
