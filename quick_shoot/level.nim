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
    goblin

  SpawnData* = tuple
    delay: float
    interval: float
    count: int
    enemy: EnemyKind
    movement: EnemyShooterMovementData
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
      (1.0, 0.75, 3, goblin, straight(vec(-1, 3).unit, 140), vec(1100, top)),
      (4.0, 0.75, 3, goblin, straight(vec(-1, -3).unit, 140), vec(1100, bottom)),
      (6.0, 2.0, 7, goblin, straight(vec(-1, 3).unit, 140), vec(1000, top)),
      (4.0, 0.75, 3, goblin, straight(vec(-1, -3).unit, 140), vec(600, bottom)),
    ],
  ),
  Level(
    name: "Level 2!",
    spawns: @[
      (1.0, 0.75, 3, goblin, sine(vec(-1, 3).unit, 140, vec(2.0, 0.7), 3.5), vec(1000, top)),
      (4.0, 0.75, 3, goblin, sine(vec(-1, -3).unit, 140, vec(-2.0, 0.7), 3.5), vec(1000, bottom)),
      (6.0, 2.0, 7, goblin, sine(vec(-1, 3).unit, 140, vec(2.0, -0.7), 3.5), vec(800, top)),
      (4.0, 0.75, 3, goblin, sine(vec(-1, -3).unit, 140, vec(-2.0, -0.7), 3.5), vec(600, bottom)),
    ],
  ),
  Level(
    name: "Level 3?",
    spawns: @[
    ],
  ),
]

proc spawnEnemy(spawn: SpawnData): Entity =
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
      data: spawn.movement,
    ),
    RemoveWhenOffscreen(buffer: 300),
    ShooterRewardOnDeath(
      xp: 3,
      gold: 2,
    ),
  ])

proc spawnTimes*(spawn: SpawnData): seq[float] =
  if spawn.count == 1:
    return @[spawn.delay]
  if spawn.count == 2:
    return @[spawn.delay, spawn.delay + spawn.interval]
  result = @[]
  var next = spawn.delay
  for _ in 0..<spawn.count:
    result.add next
    next += spawn.interval

proc toSpawn*(level: Level, prev, cur: float): seq[Entity] =
  result = @[]
  var baseDelay = 0.0
  for spawn in level.spawns:
    for delay in spawn.spawnTimes:
      let t = baseDelay + delay
      if t > prev and t <= cur:
        result.add spawn.spawnEnemy()
    baseDelay += spawn.delay
