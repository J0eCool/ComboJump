import
  component/movement,
  component/transform,
  entity,
  event,
  vec

proc physics*(entities: seq[Entity], dt: float): Events =
  forComponents(entities, e, [
    Transform, t,
    Movement, m,
  ]):
    if m.usesGravity and not m.onGround:
      m.vel.y += gravity * dt
    t.pos += m.vel * dt
