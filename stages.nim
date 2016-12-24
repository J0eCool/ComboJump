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
  vec

var
  didClickIdx = 0
  lastClickedIdx = 0

let
  stages = @[
    (proc(): Entities = @[
        newPlayer(vec(300, 400)),
        newEnemy(goblin, vec(600, 400)),
        newEnemy(ogre, vec(700, 100)),
    ]),
    (proc(): Entities = @[
        newPlayer(vec(300, 400)),
        newEnemy(goblin, vec(600, 100)),
        newEnemy(goblin, vec(600, 200)),
        newEnemy(goblin, vec(600, 300)),
        newEnemy(goblin, vec(600, 400)),
        newEnemy(ogre, vec(700, 100)),
    ]),
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
      result &= event.Event(kind: loadStage, stage: stages[didClickIdx]())
      didClickIdx = -1
