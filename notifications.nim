import
  entity,
  event,
  game_system,
  logging

# "Notification" is long to type out a lot, so use the abbreviation "N10n"
# Similar to l10n, i18n, a11y and co

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
  log "Notifications", debug, "Adding n10n - ", n10n
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
