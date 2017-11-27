import
  component/transform,
  camera,
  entity,
  event,
  game_system,
  vec

type
  CameraTargetObj* = object of ComponentObj
    verticallyLocked*: bool
    offset*: Vec
  CameraTarget* = ref object of CameraTargetObj

defineComponent(CameraTarget, @[])

defineSystem:
  priority = -100
  components = [CameraTarget, Transform]
  proc updateCamera*(camera: var Camera) =
    let diff = camera.screenSize / 2 - transform.globalPos + cameraTarget.offset
    let pre = camera.pos
    camera.pos = diff
    if cameraTarget.verticallyLocked:
      camera.pos.y = pre.y
