import
  rpg_frontier/[
    damage,
    element,
    percent,
  ]

type
  EnemyInfo* = object
    kind*: EnemyKind
    name*: string
    texture*: string
    health*: int
    damage*: int
    speed*: float
    defense*: Defense
  EnemyKind* = enum
    slime
    goblin
    ogre

proc initializeEnemyData(): array[EnemyKind, EnemyInfo] =
  for  kind,     name,      texture, health, damage, speed,
       physRes, fireRes, iceRes in [
    ( slime,  "Slime",  "Slime.png",      5,      2,   0.8,
            50,     -50,      0),
    (goblin, "Goblin", "Goblin.png",      8,      3,   1.1,
             0,       0,      0),
    (  ogre,   "Ogre",   "Ogre.png",     24,      7,   0.7,
             0,       0,      0),
  ].items:
    let info = EnemyInfo(
      kind: kind,
      name: name,
      texture: texture,
      health: health,
      damage: damage,
      speed: speed,
      defense: Defense(
        armor: 0,
        resistances: newElementSet[Percent]()
          .init(physical, physRes.Percent)
          .init(fire, fireRes.Percent)
          .init(ice, iceRes.Percent)
        ,
      ),
    )
    result[info.kind] = info
const enemyData* = initializeEnemyData()
