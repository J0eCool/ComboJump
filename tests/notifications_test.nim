import unittest

import
  entity,
  notifications

suite "Notifications":
  setup:
    var manager = newN10nManager()

  test "Buffering":
    let
      entity = newEntity("A", [])
      n10n = N10n(kind: entityRemoved, entity: entity)
    check:
      manager.get(entityRemoved).len == 0
      manager.get(entityKilled).len == 0

    manager.add(n10n)
    check:
      manager.get(entityRemoved).len == 0
      manager.get(entityKilled).len == 0

    discard updateN10nManager(@[], manager)
    let removed = manager.get(entityRemoved)
    check removed.len == 1
    if removed.len == 1:
      let first = removed[0]
      check:
        first.kind == entityRemoved
        first.entity == entity
    check manager.get(entityKilled).len == 0

    discard updateN10nManager(@[], manager)
    check:
      manager.get(entityRemoved).len == 0
      manager.get(entityKilled).len == 0
