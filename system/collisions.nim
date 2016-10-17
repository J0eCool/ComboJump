import
  component/collider,
  component/movement,
  component/transform,
  entity,
  event,
  rect

proc collidesWith(a, b: Rect): bool =
  return
    a.left <= b.right and
    a.right >= b.left and
    a.top <= b.bottom and
    a.bottom >= b.top

proc checkCollisisons*(entities: seq[Entity]): Events =
  forComponents(entities, a, [
    Collider, a_c,
    Transform, a_t,
  ]):
    a_c.collisions = @[]
    forComponents(entities, b, [
      Collider, b_c,
      Transform, b_t,
    ]):
      if a != b and a_c.layer.canCollideWith(b_c.layer) and a_t.rect.collidesWith(b_t.rect):
        a_c.collisions.add(b)
    a.withComponent(Movement, m):
      m.onGround = a_c.collisions.len > 0
      if m.onGround:
        m.vel.y = 0
