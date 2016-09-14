import ../component/movement,
       ../component/transform,
       ../entity,
       ../vec

proc physics*(entities: seq[Entity], dt: float) =
  for e in entities:
    let
      m = e.getComponent(Movement)
      t = e.getComponent(Transform)
    if m != nil and t != nil:
      t.pos += m.vel * dt
