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
  vec,
  util

type
  SpellShooterObj* = object of ComponentObj
    castTime*: float
    toCast*: SpellParse
    castIndex*: int
    castInstantly*: bool
  SpellShooter* = ref SpellShooterObj

const
  fireInputs* = [jump, spell1, spell2, spell3]

defineComponent(SpellShooter, @[
  "castTime",
  "toCast",
  "castIndex",
  "castInstantly",
])

proc isCasting*(spellShooter: SpellShooter): bool =
  spellShooter.castTime > 0.0 and (not spellShooter.toCast.instantFire)

defineSystem:
  components = [SpellShooter, Mana, Transform]
  proc updateSpellShooter*(input: InputManager, spellData: SpellData, dt: float, stats: PlayerStats) =
    let dir = vec(1, 0)
    if spellShooter.toCast.kind != error:
      spellShooter.castTime -= dt
      if spellShooter.castTime <= 0.0:
        if not spellShooter.toCast.instantFire:
          result &= spellShooter.toCast.fire(transform.globalPos, dir, stats)
        spellShooter.toCast = SpellParse()
        spellShooter.castIndex = -1
    else:
      for i in 0..<spellData.spells.len:
        if input.isHeld(fireInputs[i]) and fireInputs[i] != jump:
          let spell = spellData.spells[i]
          if spell.canCast() and mana.trySpend(spell.manaCost.float):
            spellShooter.toCast = spell
            spellShooter.castTime = spell.castTime(stats)
            spellShooter.castIndex = i
            if spell.instantFire:
              result &= spell.fire(transform.globalPos, dir, stats)
            break
