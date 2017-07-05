from sdl2 import RendererPtr

import
  color,
  input,
  entity,
  event,
  game_system,
  menu,
  resources,
  stages,
  vec,
  util

type
  LevelMenu* = ref object of Component
    menu: Node

defineComponent(LevelMenu)

proc levelMenuNode(stageData: ptr StageData): Node =
  SpriteNode(
    pos: vec(600, 450),
    size: vec(450, 600),
    color: rgb(128, 128, 128),
    children: @[
      Button(
        pos: vec(40, -265),
        size: vec(200, 50),
        onClick: (proc() =
          stageData.transitionTo = inSpellBuilder
        ),
        children: newSeqOf[Node](
          TextNode(text: "Spell Builder")
        ),
      ),
      TextNode(
        pos: vec(0, -185),
        text: "Stages:",
      ),
      List[Group](
        spacing: vec(10),
        pos: vec(0, 26),
        size: vec(400, 400),
        items: (proc(): seq[Group] = openGroups(stageData[])),
        listNodesIdx: (proc(group: Group, groupIdx: int): Node =
          var isOpen = false
          Button(
            size: vec(180, 30),
            onClick: (proc() = isOpen = not isOpen),
            children: @[
              TextNode(text: group[0].group),
              BindNode[bool](
                item: (proc(): bool = isOpen),
                node: (proc(open: bool): Node =
                  if not open:
                    Node()
                  else:
                    List[Stage](
                      spacing: vec(10),
                      pos: vec(110, -20),
                      items: (proc(): seq[Stage] = group),
                      listNodesIdx: (proc(stage: Stage, stageIdx: int): Node =
                        Button(
                          size: vec(180, 30),
                          onClick: (proc() = stageData[].click(groupIdx, stageIdx)),
                          children: newSeqOf[Node](
                            TextNode(text: stage.name)
                          ),
                        )
                      ),
                    )
                ),
              )
            ],
          )
        ),
      ),
    ],
  )

defineDrawSystem:
  priority = -100
  proc drawStageSelectMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      LevelMenu, levelMenu,
    ]:
      renderer.draw(levelMenu.menu, resources)

defineSystem:
  proc updateStageSelectMenu*(menus: var MenuManager, input: InputManager, stageData: var StageData) =
    entities.forComponents entity, [
      LevelMenu, levelMenu,
    ]:
      if levelMenu.menu == nil:
        levelMenu.menu = levelMenuNode(addr stageData)
      levelMenu.menu.update(menus, input)
