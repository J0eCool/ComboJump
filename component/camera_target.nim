import
  component/transform,
  camera,
  entity,
  event,
  system,
  vec

type CameraTarget* = ref object of Component
  vertical*: bool

defineSystem:
  proc updateCamera*(camera: var Camera) =
    entities.forComponents e, [
      CameraTarget, c,
      Transform, t,
    ]:
      let diff = camera.screenSize / 2 - t.pos
      if not c.vertical:
        camera.offset.x = diff.x
      else:
        camera.offset.y = diff.y
