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

template bindAs*(opt, name: expr, body: stmt): stmt {.immediate.} =
  case opt.kind
  of none:
    discard
  of just:
    let name = opt.value
    body
