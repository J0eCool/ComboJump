import
  entity,
  event,
  system

type
  N10nKind* = enum
    entityRemoved
    entityKilled

  N10n* = object
    case kind*: N10nKind
    of entityRemoved, entityKilled:
      entity*: Entity

  N10nManager* = object
    active, buffered: seq[N10n]

proc newN10nManager*(): N10nManager =
  N10nManager(
    active: @[],
    buffered: @[],
  )

proc add*(notifications: var N10nManager, n10n: N10n) =
  notifications.buffered.add n10n

proc get*(notifications: N10nManager, kind: N10nKind): seq[N10n] =
  result = @[]
  for n in notifications.active:
    if n.kind == kind:
      result.add n

defineSystem:
  proc updateN10nManager*(notifications: var N10nManager) =
    notifications.active = notifications.buffered
    notifications.buffered = @[]
