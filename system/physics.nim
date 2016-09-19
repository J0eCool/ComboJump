import
  component/movement,
  component/transform,
  entity,
  vec

proc physics*(entities: seq[Entity], dt: float) =
  forComponents(entities, e, [
    Transform, t,
    Movement, m,
  ]):
    t.pos += m.vel * dt
