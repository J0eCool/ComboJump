import
  component/collider,
  component/movement,
  component/transform,
  entity,
  rect

proc collidesWith(a, b: Rect): bool =
  return
    a.left <= b.right and
    a.right >= b.left and
    a.top <= b.bottom and
    a.bottom >= b.top

proc checkCollisisons*(entities: seq[Entity]) =
  forComponents(entities, a, [
    Transform, a_t,
    Collider, a_c,
  ]):
    a_c.collisions = @[]
    forComponents(entities, b, [
      Transform, b_t,
      Collider, b_c,
    ]):
      if a != b and a_c.layer.canCollideWith(b_c.layer) and a_t.rect.collidesWith(b_t.rect):
        a_c.collisions.add(b)
    a.withComponent(Movement, m):
      m.onGround = a_c.collisions.len > 0
      if m.onGround:
        m.vel.y = 0
