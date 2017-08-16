import
  rpg_frontier/[
    level,
    player_stats,
    potion,
    skill,
  ],
  rpg_frontier/battle/[
    battle_entity,
  ],
  util,
  vec

type
  TurnPair* = tuple[entity: BattleEntity, t: float]
  BattleData* = ref object of RootObj
    player*: BattleEntity
    enemies*: seq[BattleEntity]
    turnQueue*: seq[TurnPair]
    activeEntity*: BattleEntity
    selectedSkill*: SkillInfo
    stats*: PlayerStats
    potions*: seq[Potion]
    levelName*: string
    stages*: seq[Stage]
    curStageIndex*: int

proc initPotions(): seq[Potion] =
  result = @[]
  for info in allPotionInfos:
    result.add Potion(
      info: info,
      charges: info.charges,
    )

proc currentStageEnemies(battle: BattleData): seq[BattleEntity] {.nosideeffect.} =
  let
    index = battle.curStageIndex.clamp(0, battle.stages.len - 1)
    stage = battle.stages[index]
  result = @[]
  for enemyKind in stage:
    let enemy = newEnemy(enemyKind)
    enemy.pos = vec(630, 240) + vec(100, 150) * result.len
    result.add enemy

proc freshTurnOrder(battle: BattleData): seq[TurnPair] =
  result = @[]
  result.add((battle.player, random(0.0, 1.0)))
  for enemy in battle.enemies:
    result.add((enemy, random(0.0, 1.0)))

proc spawnCurrentStage*(battle: BattleData) =
  battle.enemies = battle.currentStageEnemies()
  battle.turnQueue = battle.freshTurnOrder()

proc newBattleData*(stats: PlayerStats, level: Level): BattleData =
  result = BattleData(
    player: newPlayer(),
    stats: stats,
    potions: initPotions(),
    levelName: level.name,
    stages: level.stages,
    curStageIndex: 0,
  )
  result.selectedSkill = allSkills[result.player.knownSkills[0]]
  result.spawnCurrentStage()
