import
  component/[
    transform,
  ],
  camera,
  entity,
  event,
  rect,
  game_system,
  vec,
  util

type
  RemoveWhenOffscreenObj* = object of Component
    buffer*: float
  RemoveWhenOffscreen* = ref RemoveWhenOffscreenObj

defineComponent(RemoveWhenOffscreen, @[])

proc rect(camera: Camera, buffer: float): Rect =
  rect(camera.offset + camera.screenSize / 2, camera.screenSize + 2 * vec(buffer))

defineSystem:
  components = [RemoveWhenOffscreen, Transform]
  proc updateRemoveWhenOffscreen*(dt: float, camera: Camera) =
    let
      remove = removeWhenOffscreen
      camRect = camera.rect(remove.buffer)
      isOn = transform.globalRect.intersects(camRect)
    if not isOn:
      result.add Event(kind: removeEntity, entity: entity)
