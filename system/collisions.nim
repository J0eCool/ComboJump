import
  component/collider,
  component/movement,
  component/transform,
  entity,
  event,
  rect,
  system

defineSystem:
  components = [Transform, Collider]
  proc checkCollisisons*() =
    forComponents(entities, a, [
      Transform, a_t,
      Collider, a_c,
    ]):
      a_c.collisions = @[]
      if a_c.collisionBlacklist == nil:
        a_c.collisionBlacklist = @[]
      forComponents(entities, b, [
        Transform, b_t,
        Collider, b_c,
      ]):
        if a == b:
          continue
        if not a_c.layer.canCollideWith(b_c.layer):
          continue
        if b in a_c.collisionBlacklist:
          continue
        if not a_t.rect.intersects(b_t.rect):
          continue
        a_c.collisions.add(b)
