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

let
  spell1 = @[createSingle]
  spell2 = @[
    num, count, count, count, count, createSpread,
      num, count, count, createBurst,
        update,
          wave, num, count, count, mult, grow,
        done,
        createSingle,
        despawn,
      despawn,
    ]

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
        result &= spell1.castAt(t.pos, dir)
      if input.isPressed(Input.spell2):
        result &= spell2.castAt(t.pos, dir)
