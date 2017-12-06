import
  component/[
    collider,
    health,
    limited_time,
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
  MercyInvincibilityObj* = object of Component
    duration*: float
    timer: float
  MercyInvincibility* = ref MercyInvincibilityObj

defineComponent(MercyInvincibility, @[])

proc isInvincible*(mercy: MercyInvincibility): bool =
  mercy.timer < 0.0

proc onHit*(mercy: MercyInvincibility) =
  mercy.timer = -mercy.duration

defineSystem:
  components = [MercyInvincibility]
  proc updateMercyInvincibility*(dt: float) =
    mercyInvincibility.timer += dt
