import sdl2

import
  component/[
    collider,
    health,
    popup_text,
    transform,
  ],
  entity,
  event,
  game_system,
  notifications,
  util,
  vec

type
  Damage* = ref object of Component
    damage*: int

defineSystem:
  components = [Health, Collider, Transform]
  proc updateDamage*(notifications: var N10nManager) =
    for col in collider.collisions:
      col.withComponent Damage, damage:
        health.cur -= damage.damage.float
        let popup = newEntity("DamagePopup", [
          Transform(pos: transform.pos + randomVec(50.0)),
          PopupText(text: $damage.damage, color: color(255, 255, 0, 255)),
        ])
        result.add event.Event(kind: addEntity, entity: popup)
        collider.collisionBlacklist.add col
        if health.cur <= 0:
          result.add event.Event(kind: removeEntity, entity: entity)
          notifications.add N10n(kind: entityKilled, entity: entity)
          break
