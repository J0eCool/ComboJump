import
  component/collider,
  component/movement,
  component/transform,
  entity,
  event,
  game_system,
  rect

defineSystem:
  components = [Transform, Collider]
  proc checkCollisisons*() =
    collider.collisions = @[]
    forComponents(entities, b, [
      Transform, b_t,
      Collider, b_c,
    ]):
      if entity == b:
        continue
      if not collider.layer.canCollideWith(b_c.layer):
        continue
      if collider.isBlacklisted(b):
        continue
      if not transform.rect.intersects(b_t.rect):
        continue
      collider.collisions.add(b)
