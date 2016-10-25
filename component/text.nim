import
  sdl2,
  sdl2.ttf

import
  drawing,
  entity

type Text* = ref object of Component
  text: string
  color*: Color
  cachedText*: ref RenderedText
  fontName*: string
  font*: FontPtr

proc newText*(text: string,
              color = color(255, 255, 255, 255),
              fontName = "nevis.ttf",
              ): Text =
  new result
  result.text = text
  result.color = color
  result.fontName = fontName

proc getText*(text: Text): string =
  text.text

proc setText*(text: Text, t: string) =
  text.cachedText = nil
  text.text = t
