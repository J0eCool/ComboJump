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
  proc updateDamage*(player: Entity, notifications: var N10nManager) =
    for col in collider.collisions:
      col.withComponent Damage, damage:
        health.cur -= damage.damage.float
        let
          popupColor =
            if entity == player:
              color(255, 0, 0, 255)
            else:
              color(255, 255, 0, 255)
          popup = newEntity("DamagePopup", [
            Transform(pos: transform.pos + randomVec(50.0)),
            PopupText(text: $damage.damage, color: popupColor),
          ])
        result.add event.Event(kind: addEntity, entity: popup)
        collider.collisionBlacklist.add col
        if health.cur <= 0:
          result.add event.Event(kind: removeEntity, entity: entity)
          notifications.add N10n(kind: entityKilled, entity: entity)
          break
