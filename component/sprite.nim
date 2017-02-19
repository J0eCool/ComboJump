import
  sdl2

import
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
  Sprite* = ref object of SpriteObj

defineComponent(Sprite, @["sprite"])
