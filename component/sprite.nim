from sdl2 import TexturePtr

import
  color,
  entity,
  rect

type
  SpriteData* = ref object
    texture*: TexturePtr
    size*: Rect

  SpriteObj* = object of ComponentObj
    color*: Color
    ignoresCamera*: bool
    textureName*: string
    sprite*: SpriteData
    flipX*: bool
    flipAssetX*: bool
    angle*: float
    clipRect*: Rect
  Sprite* = ref object of SpriteObj

defineComponent(Sprite, @["sprite"])
