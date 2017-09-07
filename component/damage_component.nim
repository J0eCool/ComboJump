import
  component/[
    collider,
    health,
    popup_text,
    transform,
  ],
  color,
  entity,
  event,
  game_system,
  util,
  vec

type
  DamageObj* = object of Component
    damage*: int
  Damage* = ref DamageObj

defineComponent(Damage, @[])

defineSystem:
  components = [Health, Collider, Transform]
  proc updateDamage*(player: Entity) =
    for col in collider.collisions:
      col.withComponent Damage, damage:
        health.cur -= damage.damage.float
        let
          popupColor =
            if entity == player:
              rgb(255, 0, 0)
            else:
              rgb(255, 255, 0)
          popup = newEntity("DamagePopup", [
            Transform(pos: transform.pos + randomVec(50.0)),
            PopupText(text: $damage.damage, color: popupColor),
          ])
        result.add event.Event(kind: addEntity, entity: popup)
        collider.addToBlacklist(col)
