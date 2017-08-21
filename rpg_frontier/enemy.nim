type
  EnemyInfo* = object
    kind*: EnemyKind
    name*: string
    texture*: string
    health*: int
    damage*: int
    speed*: float
  EnemyKind* = enum
    slime
    goblin
    ogre

proc initializeEnemyData(): array[EnemyKind, EnemyInfo] =
  for  kind,     name,      texture, health, damage, speed in [
    ( slime,  "Slime",  "Slime.png",     10,      2,   0.8),
    (goblin, "Goblin", "Goblin.png",      8,      3,   1.1),
    (  ogre,   "Ogre",   "Ogre.png",     24,      7,   0.7),
  ].items:
    let info = EnemyInfo(
      kind: kind,
      name: name,
      texture: texture,
      health: health,
      damage: damage,
      speed: speed,
    )
    result[info.kind] = info
const enemyData* = initializeEnemyData()
