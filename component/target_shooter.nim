from sdl2 import color
import math, random

import
  component/bullet,
  component/collider,
  component/damage,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  entity,
  event,
  option,
  rect,
  system,
  targeting,
  input,
  vec,
  util

type
  TargetShooter* = ref object of Component

defineSystem:
  proc targetedShoot*(input: InputManager) =
    result = @[]
    entities.forComponents e, [
      TargetShooter, sh,
      Targeting, targeting,
      Transform, t,
    ]:
      var dir = vec(0, -1)
      targeting.target.bindAs targetEntity:
        targetEntity.withComponent Transform, target:
          dir = (target.pos - t.pos).unit

      const speed = 1000
      if input.isPressed(Input.spell1):
        let bullet = newEntity("bullet", [
          Transform(pos: t.pos, size: vec(20)),
          Movement(vel: speed * dir),
          Collider(layer: Layer.bullet),
          Damage(damage: 5),
          Sprite(color: color(0, 255, 255, 255)),
          newBullet(1.0),
        ])
        result.add Event(kind: addEntity, entity: bullet)
