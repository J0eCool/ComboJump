import
  component/transform,
  camera,
  entity,
  event,
  game_system,
  vec

type CameraTarget* = ref object of Component
  verticallyLocked*: bool
  offset*: Vec

defineComponent(CameraTarget)

defineSystem:
  components = [CameraTarget, Transform]
  proc updateCamera*(camera: var Camera) =
    let diff = camera.screenSize / 2 - transform.globalPos + cameraTarget.offset
    if cameraTarget.verticallyLocked:
      camera.offset.y = diff.y
    else:
      camera.offset = diff
