import sdl2

import entity

type Sprite* = ref object of Component
  color*: Color
