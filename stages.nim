import
  sdl2,
  sequtils

import
  input,
  entity,
  event,
  menu,
  prefabs,
  resources,
  system,
  vec,
  util

var
  didClickIdx = 0
  lastClickedIdx = 0

type
  SpawnInfo = tuple[enemy: EnemyKind, count: int]
  Stage = object
    length: float
    enemies: seq[SpawnInfo]

let
  stages = @[
    Stage(
      length: 500,
      enemies: @[
        (goblin, 2),
        (ogre, 1),
      ],
    ),
    Stage(
      length: 800,
      enemies: @[
        (goblin, 7),
        (ogre, 2),
      ],
    ),
  ]
  levelMenu = SpriteNode(
    pos: vec(1020, 680),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      List[int](
        spacing: vec(4),
        items: (proc(): seq[int] = toSeq(0..<stages.len)),
        listNodes: (proc(stageIdx: int): Node =
          Button(
            size: vec(60, 60),
            onClick: (proc() =
              didClickIdx = stageIdx
              lastClickedIdx = stageIdx
            ),
          )
        ),
      ).Node,
    ],
  )

proc spawnedEntities(stage: Stage): Entities =
  result = @[newPlayer(vec(300, 200))]
  for spawn in stage.enemies:
    for i in 0..<spawn.count:
      let pos = vec(random(100.0, 700.0), -random(0.0, stage.length))
      result.add newEnemy(spawn.enemy, pos)

defineDrawSystem:
  priority = -100
  proc drawStages*(resources: var ResourceManager) =
    renderer.draw(levelMenu, resources)

defineSystem:
  proc stageSelect*(input: InputManager) =
    result = @[]
    levelMenu.update(input)

    if input.isPressed(restart):
      didClickIdx = lastClickedIdx

    if didClickIdx >= 0:
      result &= event.Event(kind: loadStage, stage: stages[didClickIdx].spawnedEntities())
      didClickIdx = -1
