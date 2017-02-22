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
