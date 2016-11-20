import
  component/transform,
  camera,
  entity,
  event,
  system

type CameraTarget* = ref object of Component

defineSystem:
  proc updateCamera*(camera: var Camera) =
    entities.forComponents e, [
      CameraTarget, c,
      Transform, t,
    ]:
      camera.offset.x = camera.screenSize.x/2 - t.pos.x
