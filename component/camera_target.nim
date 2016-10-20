import
  component/transform,
  camera,
  entity,
  event

type CameraTarget* = ref object of Component

proc updateCamera*(entities: Entities, camera: var Camera): Events =
  entities.forComponents e, [
    CameraTarget, c,
    Transform, t,
  ]:
    camera.offset.x = camera.screenSize.x/2 - t.pos.x
