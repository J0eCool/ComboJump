import sequtils

import
  rpg_frontier/[
    ailment,
    damage,
    element,
    enemy,
    enemy_id,
    percent,
    player_stats,
    skill_id,
    stance,
    status_effect,
  ],
  rpg_frontier/battle/[
    battle_ai,
  ],
  vec

type
  BattleEntity* = ref object
    name*: string
    texture*: string
    pos*: Vec
    offset*: Vec
    isPlayer*: bool
    health*, maxHealth*: int
    mana*, maxMana*: int
    focus*, maxFocus*: int
    baseDamage*: Damage
    speed*: float
    defense*: Defense
    stance*: Stance
    effects*: seq[StatusEffect]
    ailments*: Ailments
    ai*: BattleAI
    id: int

var nextId: int = 0
proc getNextId(): int =
  result = nextId
  nextId += 1

proc newPlayer*(stats: PlayerStats): BattleEntity =
  let
    health = 30
    mana = 16
    focus = 25
  BattleEntity(
    name: "Player",
    texture: "Wizard2.png",
    pos: vec(130, 400),
    isPlayer: true,
    health: health,
    maxHealth: health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    baseDamage: Damage(
      amounts: newElementSet[int]()
        .init(physical, 4),
      ailment: 60,
    ),
    speed: 1.0,
    stance: normalStance,
    effects: @[],
    ailments: newAilments(),
    id: getNextId(),
  )

proc newEnemy*(id: EnemyID): BattleEntity =
  let
    enemy = enemyData[id]
    mana = 5
    focus = 10
    startPhase = enemy.ai.curPhase
  BattleEntity(
    name: enemy.name,
    texture: startPhase.texture,
    health: enemy.health,
    maxHealth: enemy.health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    baseDamage: singleDamage(physical, enemy.damage),
    speed: enemy.speed,
    defense: enemy.defense,
    stance: startPhase.stance,
    effects: @[],
    ailments: newAilments(),
    ai: enemy.ai,
    id: getNextId(),
  )

proc applyAttackEffects*(damage: Damage, effects: seq[StatusEffect]): Damage =
  result = damage
  for effect in effects:
    case effect.kind
    of damageBuff:
      result.amounts = result.amounts + newElementSet(Percent(effect.amount))
    else:
      discard

proc applyDefenseEffects*(damage: Damage, effects: seq[StatusEffect]): Damage =
  result = damage
  for effect in effects:
    case effect.kind
    of damageTakenDebuff:
      result.amounts = result.amounts + newElementSet(Percent(effect.amount))
    else:
      discard

proc allEffects*(entity: BattleEntity): seq[StatusEffect] =
  entity.effects & entity.stance.effects

proc takeDamage*(entity: BattleEntity, damage: Damage): int =
  let
    applied = damage.apply(entity.defense).applyDefenseEffects(entity.allEffects)
    totalDamage = applied.total() + entity.ailments.chillEffect()
  entity.health -= totalDamage
  entity.ailments.takeDamage(applied)
  totalDamage

proc clampResources*(entity: BattleEntity) =
  entity.health = entity.health.clamp(0, entity.maxHealth)
  entity.mana = entity.mana.clamp(0, entity.maxMana)
  entity.focus = entity.focus.clamp(0, entity.maxFocus)

const attackAnimDist = 250.0
proc updateAttackAnimation*(entity: BattleEntity, pct: float) =
  let mult =
    if entity.isPlayer:
      1.0
    else:
      -1.0
  entity.offset = vec(attackAnimDist * pct * mult, 0.0)

proc tickStatusEffects*(entity: BattleEntity) =
  for effect in entity.effects.mitems:
    effect.duration -= 1
  for effect in entity.allEffects:
    case effect.kind
    of healthRegen:
      entity.health += effect.amount
    of manaRegen:
      entity.mana += effect.amount
    of focusRegen:
      entity.focus += effect.amount
    else:
      discard
  entity.effects.keepItIf(it.duration > 0)

proc debugName*(entity: BattleEntity): string =
  entity.name & " : id=" & $entity.id
