import sdl2

import component

type Sprite* = ref object of Component
  color*: Color
