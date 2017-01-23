import
  component/mana,
  component/transform,
  spells/spell_parser,
  entity,
  event,
  game_system,
  input,
  menu,
  option,
  player_stats,
  spell_creator,
  resources,
  targeting,
  vec,
  util

type
  TargetShooter* = ref object of Component
    castTime*: float
    toCast*: SpellParse
    castIndex*: int

const
  fireInputs* = [jump, spell1, spell2, spell3]

proc isCasting*(targetShooter: TargetShooter): bool =
  targetShooter.castTime > 0.0

defineSystem:
  proc updateTargetedShoot*(input: InputManager, spellData: SpellData, dt: float, stats: PlayerStats) =
    result = @[]
    entities.forComponents e, [
      TargetShooter, sh,
      Targeting, targeting,
      Mana, mana,
      Transform, t,
    ]:
      var dir = vec(0, -1)
      targeting.target.tryPos.bindAs targetPos:
        dir = (targetPos - t.pos).unit

      if sh.toCast.kind != error:
        sh.castTime -= dt
        if sh.castTime <= 0.0:
          result &= sh.toCast.fire(t.globalPos, dir, targeting.target, stats)
          sh.toCast = SpellParse()
          sh.castIndex = -1
      else:
        for i in 0..<spellData.spells.len:
          if input.isHeld(fireInputs[i]):
            let spell = spellData.spells[i]
            if spell.canCast() and mana.trySpend(spell.manaCost.float):
              sh.toCast = spell
              sh.castTime = spell.castTime(stats)
              sh.castIndex = i
              break
