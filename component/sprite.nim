import
  sdl2

import
  entity,
  rect

type
  SpriteData* = ref object
    texture*: TexturePtr
    size*: rect.Rect

  Sprite* = ref object of Component
    color*: Color
    ignoresCamera*: bool
    textureName*: string
    sprite*: SpriteData
    flipX*: bool

defineComponent(Sprite)
