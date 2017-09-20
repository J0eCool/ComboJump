import
  rpg_frontier/[
    level,
    player_stats,
    potion,
    skill,
  ],
  rpg_frontier/battle/[
    battle_ai_logic,
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
    enemyGrid*: array[3, array[3, BattleEntity]]
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

proc currentStageEnemies(battle: BattleData): seq[BattleEntity] =
  let
    index = battle.curStageIndex.clamp(0, battle.stages.len - 1)
    stage = battle.stages[index]
  result = @[]
  for enemyKind in stage:
    result.add newEnemy(enemyKind)

proc clearEnemyGrid(battle: BattleData) =
  for i, _ in battle.enemyGrid:
    for j, _ in battle.enemyGrid[i]:
      battle.enemyGrid[i][j] = nil

proc openEnemyGridCoords(battle: BattleData): seq[tuple[x, y: int]] =
  result = @[]
  for i, row in battle.enemyGrid:
    for j, enemy in row:
      if enemy == nil:
        result.add((i, j))

proc addToTurnQueue(battle: BattleData, entity: BattleEntity) =
  battle.turnQueue.add((entity, random(0.0, 1.0)))

proc addEnemy*(battle: BattleData, enemy: BattleEntity) =
  battle.enemies.add enemy
  battle.addToTurnQueue enemy
  let coord = random(battle.openEnemyGridCoords)
  enemy.pos = vec(550, 240) + vec(180, 120) * vec(coord.x, coord.y)
  battle.enemyGrid[coord.x][coord.y] = enemy

proc spawnCurrentStage*(battle: BattleData) =
  battle.turnQueue = @[]
  battle.addToTurnQueue battle.player

  battle.clearEnemyGrid()
  let enemies = battle.currentStageEnemies()
  for enemy in enemies:
    battle.addEnemy enemy

proc newBattleData*(stats: PlayerStats, level: Level): BattleData =
  result = BattleData(
    player: newPlayer(stats),
    enemies: @[],
    stats: stats,
    potions: initPotions(),
    levelName: level.name,
    stages: level.stages,
    curStageIndex: 0,
  )
  result.selectedSkill = allSkills[result.stats.skills[0]]
  result.spawnCurrentStage()

proc isEnemyTurn*(battle: BattleData): bool =
  battle.activeEntity != nil and battle.activeEntity != battle.player

proc startPlayerTurn*(battle: BattleData) =
  for potion in battle.potions.mitems:
    if potion.cooldown > 0:
      potion.cooldown -= 1

proc updateTurnQueue*(battle: BattleData, dt: float) =
  if battle.activeEntity != nil:
    return
  for pair in battle.turnQueue:
    if pair.t >= 1.0:
      battle.activeEntity = pair.entity
      return
  for pair in battle.turnQueue.mitems:
    pair.t += dt * pair.entity.speed

proc endTurn*(battle: BattleData) =
  for pair in battle.turnQueue.mitems:
    if pair.entity == battle.activeEntity:
      pair.t -= 1.0
      break
  if battle.activeEntity != battle.player:
    battle.activeEntity.finishEnemyTurn()
  battle.activeEntity = nil

proc canAfford*(battle: BattleData, skill: SkillInfo): bool =
  battle.player.mana >= skill.manaCost and
    battle.player.focus >= skill.focusCost

proc clampResources*(battle: BattleData) =
  battle.player.clampResources()
  for enemy in battle.enemies.mitems:
    enemy.clampResources()
