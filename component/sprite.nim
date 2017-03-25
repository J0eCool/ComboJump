from sdl2 import TexturePtr

import
  color,
  entity,
  rect

type
  SpriteData* = ref object
    texture*: TexturePtr
    size*: rect.Rect

  SpriteObj* = object of ComponentObj
    color*: Color
    ignoresCamera*: bool
    textureName*: string
    sprite*: SpriteData
    flipX*: bool
    angle*: float
  Sprite* = ref object of SpriteObj

defineComponent(Sprite, @["sprite"])
