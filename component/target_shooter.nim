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
  newgun,
  option,
  rect,
  system,
  targeting,
  input,
  vec,
  util

type
  TargetShooter* = ref object of Component

let spell = @[createProjectile, shoot, createProjectile, shoot]

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

      if input.isPressed(Input.spell1):
        result &= spell.castAt(t.pos, dir)
