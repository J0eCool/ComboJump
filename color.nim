import jsonparse

type Color* = object
  r*: int
  g*: int
  b*: int
  a*: int

autoObjectJsonProcs(Color)

proc rgb*(r, g, b: int): Color =
  Color(r: r, g: g, b: b, a: 255)

proc rgba*(r, g, b, a: int): Color =
  Color(r: r, g: g, b: b, a: a)

template declareBinaryOp(op: untyped): untyped =
  proc op*(a, b: Color): Color =
    Color(
      r: op(a.r, b.r),
      g: op(a.g, b.g),
      b: op(a.b, b.b),
      a: op(a.a, b.a),
    )

template declareScalarOp(op: untyped): untyped =
  proc op*(c: Color, s: float): Color =
    Color(
      r: op(c.r.float, s).int,
      g: op(c.g.float, s).int,
      b: op(c.b.float, s).int,
      a: op(c.a.float, s).int,
    )

declareBinaryOp(`+`)
declareBinaryOp(`*`)
declareScalarOp(`*`)
declareScalarOp(`/`)

proc average*(a, b: Color): Color =
  (a + b) / 2

const
  gray*        = rgb(128, 128, 128)
  lightGray*   = rgb(192, 192, 192)
  darkGray*    = rgb( 64,  64,  64)
  black*       = rgb(  0,   0,   0)
  white*       = rgb(255, 255, 255)
  lightYellow* = rgb(248, 255,  98)
  yellow*      = rgb(240, 240,  55)
  red*         = rgb(200,  40,  40)
  pureRed*     = rgb(255,   0,   0)
  blue*        = rgb( 40,  40, 200)
  pureBlue*    = rgb(  0,   0, 255)
  green*       = rgb( 40, 200,  40)
  pureGreen*   = rgb(  0, 255,   0)
