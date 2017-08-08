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
  for tup in @[
    (slime, "Slime", 3, "Slime.png"),
    (goblin, "Goblin", 4, "Goblin.png"),
    (ogre, "Ogre", 5, "Ogre.png"),
  ]:
    let info = EnemyInfo(
      kind: tup[0],
      name: tup[1],
      health: tup[2],
      texture: tup[3],
    )
    result[info.kind] = info
const enemyData* = initializeEnemyData()
