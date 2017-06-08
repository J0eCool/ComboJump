import
  component/[
    collider,
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
  proc checkCollisions*() =
    var byLayer: array[Layer, seq[Entity]]
    for layer in Layer:
      byLayer[layer] = @[]
    forComponents(entities, entity, [
      Transform, transform,
      Collider, collider,
    ]):
      byLayer[collider.layer].add entity

    forComponents(entities, entity, [
      Transform, transform,
      Collider, collider,
    ]):
      collider.collisions =
        if collider.bufferedCollisions != nil:
          collider.bufferedCollisions
        else:
          @[]
      collider.bufferedCollisions = @[]
      for layer in Layer:
        if not collider.layer.canCollideWith(layer):
          continue
        let inLayer = byLayer[layer]
        forComponents(inLayer, b, [
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
