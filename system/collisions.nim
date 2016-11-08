import
  component/collider,
  component/movement,
  component/transform,
  entity,
  event,
  rect

proc checkCollisisons*(entities: seq[Entity]): Events =
  forComponents(entities, a, [
    Transform, a_t,
    Collider, a_c,
  ]):
    a_c.collisions = @[]
    forComponents(entities, b, [
      Transform, b_t,
      Collider, b_c,
    ]):
      if a != b and a_c.layer.canCollideWith(b_c.layer) and a_t.rect.intersects(b_t.rect):
        a_c.collisions.add(b)
