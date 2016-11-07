import math, random
from sdl2 import color

import
  component/bullet,
  component/collider,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  gun,
  entity,
  event,
  option,
  rect,
  vec,
  util

proc playerShoot*(entities: seq[Entity], dt: float): seq[Event] =
  result = @[]
  forComponents(entities, e, [
    PlayerShooting, p,
    PlayerControl, pc,
    Mana, m,
    Transform, t,
  ]):
    if p.heldSpell != 0:
      let spell = p.spells[p.heldSpell - 1]
      m.held += spell.manaChargeRate * dt
      m.held = min(m.held, m.cur)
      if not p.isSpellHeld and m.held > spell.minCost:
        if m.trySpend(m.held):
          let shotPoint = t.rect.center + vec(t.size.x, 0) * 0.5 * pc.facingDir
          result = spell.shoot(m.held, shotPoint, pc.facingDir)
        m.held = 0
        p.heldSpell = 0
