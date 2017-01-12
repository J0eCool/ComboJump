import
  enemy_kind,
  util

type
  SpawnInfo = tuple[enemy: EnemyKind, proportion: float]
  Spawns = seq[SpawnInfo]
  StageDesc* = object
    stage*: int
    length*: float
    enemies*: int
    spawns*: Spawns
  AreaInfo* = object
    name*: string
    keyStages*: seq[StageDesc]

const areaData* = [
  AreaInfo(
    name: "Field",
    keyStages: @[
      StageDesc(stage: 1, length: 500, enemies: 5,
        spawns: @[(goblin, 1.0)]),
      StageDesc(stage: 3, length: 1000, enemies: 12,
        spawns: @[(goblin, 5.0), (ogre, 1.0)]),
    ],
  ),
  AreaInfo(
    name: "Grassland",
    keyStages: @[
      StageDesc(stage: 1, length: 900, enemies: 10,
        spawns: @[(goblin, 5.0), (ogre, 2.0)]),
      StageDesc(stage: 3, length: 600, enemies: 9,
        spawns: @[(goblin, 5.0), (ogre, 3.0)]),
      StageDesc(stage: 5, length: 1600, enemies: 20,
        spawns: @[(goblin, 4.0), (ogre, 4.0), (mushroom, 2.0)]),
    ],
  ),
]

proc numStages*(area: AreaInfo): int =
  for desc in area.keyStages:
    result.max = desc.stage

proc proportionOf(spawns: Spawns, enemy: EnemyKind): float =
  for spawn in spawns:
    if spawn.enemy == enemy:
      return spawn.proportion
  return 0.0

proc contains(spawns: Spawns, enemy: EnemyKind): bool =
  spawns.proportionOf(enemy) > 0.0

proc lerp(t: float, a, b: Spawns): Spawns =
  var enemies = newSeq[EnemyKind]()
  for spawn in a:
    enemies.add spawn.enemy
  for spawn in b:
    if not (spawn.enemy in enemies):
      enemies.add spawn.enemy
  result = @[]
  for e in enemies:
    result.add((e, t.lerp(a.proportionOf(e), b.proportionOf(e))))

proc stageDesc*(area: AreaInfo, stage: int): StageDesc =
  var
    lo = area.keyStages[0]
    hi = area.keyStages[0]
  for s in area.keyStages:
    if s.stage == stage:
      return s
    lo = hi
    hi = s
    if lo.stage < stage and hi.stage > stage:
      break
  let t = (stage - lo.stage) / (hi.stage - lo.stage)
  return StageDesc(
    stage: stage,
    length: t.lerp(lo.length, hi.length),
    enemies: t.lerp(lo.enemies.float, hi.enemies.float).int,
    spawns: t.lerp(lo.spawns, hi.spawns),
  )

proc totalProportion(spawns: Spawns): float =
  for spawn in spawns:
    result += spawn.proportion

proc randomEnemyKinds*(stage: StageDesc): seq[EnemyKind] =
  result = @[]
  for i in 0..<stage.enemies:
    var roll = random(0.0, stage.spawns.totalProportion)
    for spawn in stage.spawns:
      roll -= spawn.proportion
      if roll <= 0.0:
        result.add spawn.enemy
        break

proc `$`(stage: StageDesc): string =
  "Stage " & $stage.stage &
    " : length=" & $stage.length &
    ", enemies=" & $stage.enemies &
    ", spawns=" & $stage.spawns
