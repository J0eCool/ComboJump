import
  sdl2,
  sdl2.ttf

import entity

type Text* = ref object of Component
  text: string
  color*: Color
  texture*: TexturePtr

proc newText*(text: string, color: Color = color(255, 255, 255, 255)): Text =
  new result
  result.text = text
  result.color = color

proc getText*(text: Text): string =
  text.text

proc setText*(text: var Text, t: string) =
  text.texture = nil
  text.text = t
