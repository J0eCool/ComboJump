import
  rpg_frontier/[
    damage,
    element,
    skill_id,
    percent,
    stance,
  ],
  rpg_frontier/battle/[
    battle_ai,
  ]

type
  EnemyInfo* = object
    kind*: EnemyKind
    name*: string
    health*: int
    damage*: int
    speed*: float
    defense*: Defense
    ai*: BattleAI
  EnemyKind* = enum
    slime
    goblin
    ogre
    bossOgre

proc initializeEnemyData(): array[EnemyKind, EnemyInfo] =
  for    kind,       name, health, damage, speed,
      physRes,    fireRes, iceRes,
      ai in [
    (   slime,    "Slime",      5,      2,   0.8,
           50,        -50,      0,
      simpleAI("Slime.png")),
    (  goblin,   "Goblin",      8,      3,   1.1,
            0,          0,      0,
      simpleAI("Goblin.png")),
    (    ogre,     "Ogre",     24,      7,   0.7,
            0,          0,      0,
      simpleAI("Ogre.png")),
    (bossOgre, "Ogre Boss",    100,      5,  0.75,
            0,          0,      0,
      BattleAI(phases: @[
        BattleAIPhase(
          stance: defensiveStance,
          texture: "BlueOgre.png",
          duration: 2,
          skills: @[attack],
        ),
        BattleAIPhase(
          stance: powerStance,
          texture: "PinkOgre.png",
          duration: 2,
          skills: @[attack],
        ),
      ])),
  ].items:
    let info = EnemyInfo(
      kind: kind,
      name: name,
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
      ai: ai,
    )
    result[kind] = info
const enemyData* = initializeEnemyData()
