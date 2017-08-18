import
  rpg_frontier/[
    enemy,
    skill_kind,
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
    damage*: int
    speed*: float
    knownSkills*: seq[SkillKind]

proc newPlayer*(): BattleEntity =
  let
    health = 10
    mana = 8
    focus = 20
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
    damage: 1,
    speed: 1.0,
    knownSkills: @[
      attack,
      powerAttack,
      cleave,
    ],
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
    damage: enemy.damage,
    speed: enemy.speed,
    knownSkills: @[attack],
  )

proc takeDamage*(entity: BattleEntity, damage: int) =
  entity.health -= damage

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
