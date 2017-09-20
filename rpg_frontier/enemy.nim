import
  rpg_frontier/[
    damage,
    element,
    enemy_id,
    skill_id,
    percent,
    stance,
  ],
  rpg_frontier/battle/[
    battle_ai,
  ]

type
  EnemyInfo* = object
    id*: EnemyID
    name*: string
    health*: int
    damage*: int
    speed*: float
    defense*: Defense
    ai*: BattleAI

proc initializeEnemyData(): array[EnemyID, EnemyInfo] =
  for      id,       name, health, damage, speed,
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
    (bossOgre, "Ogre Boss",   100,      5,  0.75,
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
    (summoner, "Summoner",    100,      2,  0.4,
            0,          0,      0,
      BattleAI(phases: @[
        BattleAIPhase(
          kind: summonPhaseKind,
          stance: normalStance,
          texture: "PinkOgre.png",
          duration: 1,
          skills: @[attack],
          toSummon: @[goblin],
        ),
      ])),
  ].items:
    let info = EnemyInfo(
      id: id,
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
    result[id] = info
  for id in EnemyID:
    assert result[id].name != nil, "Uninitialized enemy id: " & $id
const enemyData* = initializeEnemyData()
