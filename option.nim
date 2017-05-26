import macros

type
  OptionKind* = enum
    none
    just
  Option*[T] = object
    case kind*: OptionKind
    of none:
      discard
    of just:
      value*: T

proc makeNone*[T](): Option[T] =
  Option[T](kind: none)

proc makeJust*[T](value: T): Option[T] =
  Option[T](kind: just, value: value)

template bindAs*(opt: typed, name, body: untyped): untyped =
  case opt.kind
  of none:
    discard
  of just:
    let name = opt.value
    body

# TODO: this only works when called like `bindOr(a, b, c, d)`
template bindOr*(opt: typed, name, orBody, body: untyped): untyped =
  case opt.kind
  of none:
    orBody
  of just:
    let name = opt.value
    body

proc isNone*[T](opt: Option[T]): bool =
  opt.kind == none

proc getOr*[T](opt: Option[T], orVal: T): T =
  case opt.kind
  of none:
    orVal
  of just:
    opt.value

proc get*[T: ref object](opt: Option[T]): T =
  getOr(opt, nil)

proc `==`*[T](a, b: Option[T]): bool =
  a.kind == b.kind and (a.kind == none or a.value == b.value)
