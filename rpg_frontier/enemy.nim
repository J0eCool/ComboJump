type
  EnemyInfo* = object
    kind*: EnemyKind
    name*: string
    health*: int
    texture*: string
  EnemyKind* = enum
    slime
    goblin
    ogre

proc initializeEnemyData(): array[EnemyKind, EnemyInfo] =
  for  kind,     name, health,      texture in [
    ( slime,  "Slime",      3,  "Slime.png"),
    (goblin, "Goblin",      4, "Goblin.png"),
    (  ogre,   "Ogre",      5,   "Ogre.png"),
  ].items:
    let info = EnemyInfo(
      kind: kind,
      name: name,
      health: health,
      texture: texture,
    )
    result[info.kind] = info
const enemyData* = initializeEnemyData()
