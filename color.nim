import jsonparse

type Color* = object
  r*: int
  g*: int
  b*: int
  a*: int

proc rgb*(r, g, b: int): Color =
  Color(r: r, g: g, b: b, a: 255)

proc rgba*(r, g, b, a: int): Color =
  Color(r: r, g: g, b: b, a: a)

autoObjectJSONProcs(Color)

const
  gray*        = rgb(128, 128, 128)
  lightGray*   = rgb(192, 192, 192)
  darkGray*    = rgb( 64,  64,  64)
  black*       = rgb(  0,   0,   0)
  white*       = rgb(255, 255, 255)
  lightYellow* = rgb(248, 255,  98)
