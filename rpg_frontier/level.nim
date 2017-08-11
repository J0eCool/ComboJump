import
  rpg_frontier/[
    enemy,
  ]

type
  Level* = object
    name*: string
    stages*: seq[Stage]
  Stage* = EnemyKind

const allLevels* = @[
  Level(
    name: "Level 1",
    stages: @[slime, slime, goblin],
  ),
  Level(
    name: "Level 2!?",
    stages: @[goblin, slime, goblin, ogre],
  ),
]
