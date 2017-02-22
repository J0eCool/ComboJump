import
  sdl2.ttf

import
  color,
  drawing,
  entity

type Text* = ref object of Component
  text*: string
  color*: Color
  fontName*: string
  font*: FontPtr
  ignoresCamera*: bool

defineComponent(Text)

proc newText*(text: string,
              color = rgb(255, 255, 255),
              fontName = "nevis.ttf",
              ): Text =
  new result
  result.text = text
  result.color = color
  result.fontName = fontName
  result.ignoresCamera = true
