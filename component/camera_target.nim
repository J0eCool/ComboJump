import
  component/transform,
  camera,
  entity,
  event,
  system,
  vec

type CameraTarget* = ref object of Component
  vertical*: bool
  offset*: Vec

defineSystem:
  components = [CameraTarget, Transform]
  proc updateCamera*(camera: var Camera) =
    let diff = camera.screenSize / 2 - transform.globalPos + cameraTarget.offset
    if not cameraTarget.vertical:
      camera.offset.x = diff.x
    else:
      camera.offset.y = diff.y
