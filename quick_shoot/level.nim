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
  util,
  vec

type
  EnemyKind* = enum
    goblin
    blueGoblin

  SpawnPos* = object
    pos: Vec
    randomOffset: Vec

  SpawnData* = tuple
    delay: float
    interval: float
    count: int
    enemy: EnemyKind
    movement: EnemyShooterMovementData
    pos: SpawnPos

  Level* = object
    name*: string
    spawns*: seq[SpawnData]

proc `==`*(a, b: Level): bool =
  a.name == b.name

proc spawnOnRight*(y: float, offset = vec(25, 150)): SpawnPos =
  SpawnPos(
    pos: vec(1300.0, y),
    randomOffset: offset,
  )
proc spawnOnTop*(x: float, offset = vec(150, 25)): SpawnPos =
  SpawnPos(
    pos: vec(x, -100.0),
    randomOffset: offset,
  )
proc spawnOnBottom*(x: float, offset = vec(150, 25)): SpawnPos =
  SpawnPos(
    pos: vec(x, 1000.0),
    randomOffset: offset,
  )

let allLevels* = @[
  Level(
    name: "Level 1",
    spawns: @[
      (1.0, 0.75, 3, goblin, straight(vec(-2,  1).unit, 140), spawnOnRight(50)),
      (4.0, 0.75, 3, goblin, straight(vec(-2, -1).unit, 140), spawnOnRight(850)),
      (6.0, 2.00, 7, goblin, straight(vec(-3,  1).unit, 140), spawnOnRight(200)),
      (4.0, 0.75, 3, goblin, straight(vec(-1, -3).unit, 140), spawnOnBottom(900)),
    ],
  ),
  Level(
    name: "Level 2!",
    spawns: @[
      (1.0, 0.75, 3, goblin, sine(vec(-1,  3).unit, 140, vec( 2.0,  0.7).unit, 3.5), spawnOnTop(1000)),
      (4.0, 0.75, 3, goblin, sine(vec(-1, -3).unit, 140, vec(-2.0,  0.7).unit, 3.5), spawnOnBottom(1000)),
      (6.0, 2.00, 7, goblin, sine(vec(-1,  3).unit, 140, vec( 2.0, -0.7).unit, 3.5), spawnOnTop(800)),
      (4.0, 0.75, 3, goblin, sine(vec(-1, -3).unit, 140, vec(-2.0, -0.7).unit, 3.5), spawnOnBottom(600)),
    ],
  ),
  Level(
    name: "Level 3?",
    spawns: @[
      (1.0, 0.75, 3, blueGoblin, curve(vec(0,  1), 220, vec(-1.5,  0.5), 4.0), spawnOnTop(1200)),
      (4.0, 0.75, 3, blueGoblin, curve(vec(0, -1), 220, vec(-1.5, -0.5), 4.0), spawnOnBottom(1200)),
      (6.0, 2.00, 7, blueGoblin, curve(vec(0,  1), 220, vec(-1.5,  0.5), 4.0), spawnOnTop(1000)),
      (4.0, 0.75, 3, blueGoblin, curve(vec(0, -1), 220, vec(-1.5, -0.5), 4.0), spawnOnBottom(900)),
    ],
  ),
]

proc toPos(pos: SpawnPos): Vec =
  pos.pos + random(-pos.randomOffset, pos.randomOffset) / 2.0

proc spawnEnemy(spawn: SpawnData): Entity =
  let texture =
    case spawn.enemy
    of goblin:
      "Goblin.png"
    of blueGoblin:
      "BlueGoblin.png"
  newEntity("Enemy", [
    Transform(pos: spawn.pos.toPos, size: vec(50, 50)),
    Movement(),
    Collider(layer: Layer.enemy),
    Sprite(textureName: texture),
    newHealth(5),
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
