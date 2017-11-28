from sdl2 import RendererPtr

import
  component/[
    limited_time,
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
  PopupTextObj* = object of ComponentObj
    text*: string
    height*: float
    color*: Color
  PopupText* = ref object of PopupTextObj

defineComponent(PopupText, @[])

defineDrawSystem:
  priority = -50
  components = [PopupText, LimitedTime, Transform]
  proc drawPopupText*(resources: ResourceManager, camera: Camera) =
    let
      font = resources.loadFont("nevis.ttf")
      height = popupText.height * limitedTime.pct
      pos = transform.globalPos - vec(0.0, height) + camera.offset
    renderer.drawBorderedText(popupText.text, pos, font, popupText.color)
