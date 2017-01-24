import unittest

import
  component/[
    collider,
    damage,
    health,
    popup_text,
    transform,
  ],
  entity,
  event,
  notifications,
  vec

suite "Damage":
  setup:
    var notifications = newN10nManager()
    let
      deadEntity = newEntity("DeadEntity", [newHealth(0).Component])
      collidedEntity = newEntity("CollidedEntity", [
        newHealth(5),
        Collider(collisions: @[
          newEntity("Damage", [Damage(damage: 10).Component]),
        ]),
        Transform(),
      ])
      survivingEntity = newEntity("SurvivingEntity", [
        newHealth(25),
        Collider(collisions: @[
          newEntity("Damage", [Damage(damage: 10).Component]),
        ]),
        Transform(),
      ])

  test "Entity dies when hit":
    let entities = @[collidedEntity]
    discard updateDamage(entities, nil)
    let events = updateHealth(entities, notifications)
    check:
      events.len == 1
      events[0].kind == removeEntity
      events[0].entity == collidedEntity

  test "Entity dies at 0 health":
    let events = updateHealth(@[deadEntity], notifications)
    check:
      events.len == 1
      events[0].kind == removeEntity
      events[0].entity == deadEntity

  test "Entity doesn't die with health left":
    let entities = @[survivingEntity]
    discard updateDamage(entities, nil)
    let events = updateHealth(entities, notifications)
    check events.len == 0

  test "Damage creates popups":
    let entities = @[survivingEntity]
    let events = updateDamage(entities, nil)
    check:
      events.len == 1
      events[0].kind == addEntity
      events[0].entity.getComponent(PopupText) != nil

  test "Death sends notifications":
    let entities = @[deadEntity]
    discard updateHealth(entities, notifications)
    discard updateN10nManager(entities, notifications)
    let n10ns = notifications.get(entityKilled)
    check:
      n10ns.len == 1
      n10ns[0].entity == deadEntity
