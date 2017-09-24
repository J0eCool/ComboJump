from sdl2 import RendererPtr

import
  component/[
    transform,
  ],
  camera,
  color,
  drawing,
  entity,
  event,
  game_system,
  resources,
  vec

type
  PopupText* = ref object of Component
    text*: string
    color*: Color
    liveTime: float

defineComponent(PopupText)

const
  timeToLive = 1.5
  popupDist = 300

defineSystem:
  components = [PopupText]
  proc updatePopupText*(dt: float) =
    popupText.liveTime += dt
    if popupText.liveTime >= timeToLive:
      result.add event.Event(kind: removeEntity, entity: entity)

defineDrawSystem:
  priority = -50
  components = [PopupText, Transform]
  proc drawPopupText*(resources: ResourceManager, camera: Camera) =
    let
      font = resources.loadFont("nevis.ttf")
      pos = transform.globalPos - vec(0.0, popupDist * popupText.liveTime / timeToLive) + camera.offset
    renderer.drawBorderedText(popupText.text, pos, font, popupText.color)
