import
  rpg_frontier/[
    damage,
    element,
    skill_id,
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
    skills*: seq[SkillID]
  EnemyKind* = enum
    slime
    goblin
    ogre
    blueOgre

proc initializeEnemyData(): array[EnemyKind, EnemyInfo] =
  for    kind,       name,    texture, health, damage, speed,
      physRes,    fireRes,     iceRes,
      skills in [
    (   slime,    "Slime",    "Slime",      5,      2,   0.8,
           50,        -50,          0,
      @[attack]),
    (  goblin,   "Goblin",   "Goblin",      8,      3,   1.1,
            0,          0,          0,
      @[attack]),
    (    ogre,     "Ogre",     "Ogre",     24,      7,   0.7,
            0,          0,          0,
      @[attack]),
    (blueOgre, "BlueOgre", "BlueOgre",    100,      5,  0.75,
            0,          0,          0,
      @[chill, scorch]),
  ].items:
    let info = EnemyInfo(
      kind: kind,
      name: name,
      texture: texture & ".png",
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
      skills: skills,
    )
    result[info.kind] = info
const enemyData* = initializeEnemyData()
