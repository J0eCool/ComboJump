import
  component/[
    collider,
    movement,
    transform,
  ],
  camera,
  color,
  drawing,
  entity,
  event,
  game_system,
  rect
from sdl2 import RendererPtr

var debugDrawColliders* = false
defineDrawSystem:
  components = [Transform, Collider]
  proc drawColliders*(camera: Camera) =
    if not debugDrawColliders:
      return

    let r = transform.globalRect + camera.offset
    renderer.drawRect(r, color.red)

defineSystem:
  components = [Transform, Collider]
  proc checkCollisisons*() =
    collider.collisions =
      if collider.bufferedCollisions != nil:
        collider.bufferedCollisions
      else:
        @[]
    collider.bufferedCollisions = @[]
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
      if not transform.globalRect.intersects(b_t.globalRect):
        continue
      collider.collisions.add(b)
