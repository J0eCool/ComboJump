import
  component/[
    collider,
    damage_component,
    enemy_attack,
    enemy_shooter_movement,
    grid_control,
    health,
    movement,
    player_shooter_attack,
    remove_when_offscreen,
    shooter_reward_on_death,
    sprite,
    transform,
  ],
  entity,
  vec

type
  EnemyKind* = enum
    goblinDown
    goblinUp

  SpawnData* = tuple
    startTime: float
    interval: float
    count: int
    enemy: EnemyKind
    pos: Vec

  Level* = object
    name*: string
    spawns*: seq[SpawnData]

proc `==`*(a, b: Level): bool =
  a.name == b.name

const
  top = -100
  bottom = 1000

let allLevels* = @[
  Level(
    name: "Level 1",
    spawns: @[
      (1.0, 0.75, 3, goblinDown, vec(1200, top)),
      (5.0, 0.75, 3, goblinUp, vec(1200, bottom)),
      (11.0, 2.0, 7, goblinDown, vec(1100, top)),
      (15.0, 0.75, 3, goblinUp, vec(600, bottom)),
    ],
  ),
  Level(
    name: "Level 2!",
    spawns: @[
    ],
  ),
  Level(
    name: "Level 3?",
    spawns: @[
    ],
  ),
]

proc spawnEnemy(spawn: SpawnData): Entity =
  let moveKind =
    case spawn.enemy
    of goblinUp:
      moveUp
    of goblinDown:
      moveDown
  newEntity("Goblin", [
    Transform(pos: spawn.pos, size: vec(50, 50)),
    Movement(),
    Collider(layer: Layer.enemy),
    Sprite(textureName: "Goblin.png"),
    newHealth(8),
    EnemyAttack(
      damage: 1,
      size: 25,
      attackSpeed: 1.2,
      bulletSpeed: 400,
      attackDir: vec(-1, 0),
    ),
    EnemyShooterMovement(
      kind: moveKind,
      moveSpeed: 120,
    ),
    RemoveWhenOffscreen(buffer: 100),
    ShooterRewardOnDeath(
      xp: 3,
      gold: 2,
    ),
  ])

proc spawnTimes*(spawn: SpawnData): seq[float] =
  if spawn.count == 1:
    return @[spawn.startTime]
  if spawn.count == 2:
    return @[spawn.startTime, spawn.startTime + spawn.interval]
  result = @[]
  var next = spawn.startTime
  for _ in 0..<spawn.count:
    result.add next
    next += spawn.interval

proc toSpawn*(level: Level, prev, cur: float): seq[Entity] =
  result = @[]
  for spawn in level.spawns:
    # if cur < spawn.startTime or prev > spawn.endTime:
    #   continue
    for t in spawn.spawnTimes:
      if t > prev and t <= cur:
        result.add spawn.spawnEnemy()
