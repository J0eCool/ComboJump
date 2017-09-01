import sequtils

import
  rpg_frontier/[
    ailment,
    damage,
    element,
    enemy,
    percent,
    skill_id,
    status_effect,
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
    knownSkills*: seq[SkillID]
    effects*: seq[StatusEffect]
    ailments*: Ailments
    id: int

var nextId: int = 0
proc getNextId(): int =
  result = nextId
  nextId += 1

proc newPlayer*(): BattleEntity =
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
    knownSkills: @[
      attack,
      doubleHit,
      flameblast,
      scorch,
      chill,
    ],
    effects: @[],
    ailments: newAilments(),
    id: getNextId(),
  )

proc newEnemy*(kind: EnemyKind): BattleEntity =
  let
    enemy = enemyData[kind]
    mana = 5
    focus = 10
  BattleEntity(
    name: enemy.name,
    texture: enemy.texture,
    health: enemy.health,
    maxHealth: enemy.health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    baseDamage: singleDamage(physical, enemy.damage),
    speed: enemy.speed,
    defense: enemy.defense,
    knownSkills: @[attack],
    effects: @[],
    ailments: newAilments(),
    id: getNextId(),
  )

proc takeDamage*(entity: BattleEntity, damage: Damage): int =
  let
    applied = damage.apply(entity.defense)
    totalDamage = applied.total()
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
