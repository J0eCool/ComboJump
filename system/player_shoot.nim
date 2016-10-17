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

let
  normalSpell = createSpell(
    (projectileBase,
      @[(damage, 100.0),
        (fiery, 50.0)]
    ),
    (projectileBase,
      @[(damage, 40.0),
        (spread, 60.0)]
    ),
  )
  spreadSpell = createSpell(
    (projectileBase,
      @[(damage, 40.0),
        (spread, 60.0)]
    ),
    (projectileBase,
      @[(damage, 40.0),
        (spread, 60.0)]
    ),
    (projectileBase,
      @[(damage, 40.0),
        (spread, 60.0),
        (homing, 40.0),
        (fiery, 30.0),]
    ),
  )
  homingSpell = createSpell(
    (projectileBase,
      @[(damage, 20.0),
        (spread, 40.0),
        (homing, 40.0),
        (fiery, 20.0)]
    ),
  )

  spells = [normalSpell, spreadSpell, homingSpell]

proc playerShoot*(entities: seq[Entity], dt: float): seq[Event] =
  result = @[]
  forComponents(entities, e, [
    PlayerControl, p,
    Mana, m,
    Transform, t,
  ]):
    if p.heldSpell != 0:
      let spell = spells[p.heldSpell - 1]
      m.held += spell.manaChargeRate * dt
      m.held = min(m.held, m.cur)
      if not p.isSpellHeld and m.held > spell.minCost:
        if m.trySpend(m.held):
          let shotPoint = t.rect.center + t.size * 0.5 * p.facingDir - spell.size.amt(m.held) / 2
          result = spell.shoot(m.held, shotPoint, p.facingDir)
        m.held = 0
        p.heldSpell = 0
