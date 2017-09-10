import
  rpg_frontier/[
    enemy,
  ]

type
  Level* = object
    name*: string
    stages*: seq[Stage]
  Stage* = seq[EnemyKind]

const allLevels* = @[
  Level(
    name: "Field - 1",
    stages: @[
      @[slime],
      @[slime],
      @[goblin],
    ],
  ),
  Level(
    name: "Field - 2",
    stages: @[
      @[goblin],
      @[slime],
      @[goblin, slime],
      @[ogre],
    ],
  ),
  Level(
    name: "Field - 3",
    stages: @[
      @[slime, slime],
      @[slime, goblin],
      @[slime, slime, slime],
      @[slime, goblin, slime],
    ],
  ),
  Level(
    name: "Field - Boss",
    stages: @[
      @[blueOgre],
    ],
  ),
]
