import
  component/[
    collider,
    health,
    limited_time,
    mercy_invincibility,
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
    canRepeat*: bool
  Damage* = ref DamageObj

defineComponent(Damage, @[])

defineSystem:
  components = [Health, Collider, Transform]
  proc updateDamage*(player: Entity) =
    let mercy = entity.getComponent(MercyInvincibility)
    if mercy != nil and mercy.isInvincible:
      continue
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
            PopupText(
              text: $damage.damage,
              height: 125,
              color: popupColor,
            ),
            LimitedTime(limit: 0.75),
          ])
        result.add event.Event(kind: addEntity, entity: popup)
        if not damage.canRepeat:
          collider.addToBlacklist(col)
        if mercy != nil:
          mercy.onHit()
