import
  sdl2,
  sequtils

import
  component/collider,
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
  clickedStage = 0
  currentStage = 0
  highestStageBeaten = -1

type
  SpawnInfo = tuple[enemy: EnemyKind, count: int]
  Stage = object
    name: string
    length: float
    enemies: seq[SpawnInfo]

let
  stages = @[
    Stage(
      name: "1-1",
      length: 500,
      enemies: @[
        (goblin, 2),
        (ogre, 1),
      ],
    ),
    Stage(
      name: "1-2",
      length: 800,
      enemies: @[
        (goblin, 7),
        (ogre, 2),
      ],
    ),
    Stage(
      name: "1-3",
      length: 2000,
      enemies: @[
        (goblin, 16),
        (ogre, 4),
      ],
    ),
  ]
  levelMenu = SpriteNode(
    pos: vec(1020, 680),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      List[int](
        spacing: vec(10),
        size: vec(300, 400),
        width: 5,
        items: (proc(): seq[int] = toSeq(0..min(highestStageBeaten + 1, stages.len - 1))),
        listNodes: (proc(stageIdx: int): Node =
          Button(
            size: vec(50, 50),
            onClick: (proc() =
              clickedStage = stageIdx
            ),
            children: @[
              TextNode(text: stages[stageIdx].name).Node,
            ],
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
      clickedStage = currentStage

    var didFindEnemy = false
    if clickedStage >= 0:
      result &= event.Event(kind: loadStage, stage: stages[clickedStage].spawnedEntities())
      currentStage = clickedStage
      clickedStage = -1
      # Need to not trigger next stage when spawning the first stage
      didFindEnemy = true

    entities.forComponents e, [
      Collider, collider,
    ]:
      if collider.layer == enemy:
        didFindEnemy = true
        break
    if not didFindEnemy:
      highestStageBeaten.max = currentStage
