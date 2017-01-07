import
  sdl2,
  sequtils,
  tables

import
  component/collider,
  component/sprite,
  component/target_shooter,
  component/transform,
  menu/spell_hud_menu,
  menu/rune_menu,
  input,
  entity,
  event,
  jsonparse,
  menu,
  newgun,
  prefabs,
  resources,
  spell_creator,
  stages,
  system,
  vec,
  util

type
  LevelMenu* = ref object of Component
    menu: Node

proc maxStageIndex(stageData: StageData): int =
  min(stageData.highestStageBeaten + 1,
      levels.len - 1)

proc maxGroupIndex(stageData: StageData): int =
  min((stageData.highestStageBeaten + 1) div 5,
      (levels.len - 1) div 5)

proc levelMenuNode(stageData: ptr StageData): Node =
  SpriteNode(
    pos: vec(600, 450),
    size: vec(300, 600),
    color: color(128, 128, 128, 255),
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
      List[int](
        spacing: vec(10),
        pos: vec(0, 26),
        size: vec(300, 400),
        width: 5,
        items: (proc(): seq[int] =
          toSeq(0..stageData[].maxGroupIndex)
        ),
        listNodes: (proc(groupIdx: int): Node =
          var isOpen = false
          Button(
            size: vec(50, 50),
            onClick: (proc() = isOpen = not isOpen),
            children: newSeqOf[Node](
              BindNode[bool](
                item: (proc(): bool = isOpen),
                node: (proc(open: bool): Node =
                  if not open:
                    Node()
                  else:
                    List[int](
                      spacing: vec(10),
                      pos: vec(0, 60),
                      width: 5,
                      items: (proc(): seq[int] =
                        if groupIdx < stageData[].maxGroupIndex:
                          result = toSeq(0..<5)
                        else:
                          result = @[]
                          for i in 0..stageData[].maxStageIndex mod 5:
                            result.add i
                      ),
                      listNodes: (proc(stageIdx: int): Node =
                        let stageIdx = stageIdx + 5 * groupIdx
                        Button(
                          size: vec(50),
                          onClick: (proc() =
                            stageData.clickedStage = stageIdx
                          ),
                          children: @[
                            TextNode(
                              pos: vec(0, -10),
                              text: levels[stageIdx].name,
                            ),
                            SpriteNode(
                              pos: vec(10, 10),
                              size: vec(24, 24),
                              textureName: levels[stageIdx].runeReward.textureName,
                            ),
                          ],
                        )
                      ),
                    )
                ),
              )
            ),
          )
        ),
      ),
      stringListNode(@[
          "Instructions:",
          "Clear stages to collect runes",
          "Use runes to build spells",
          " ",
          "Controls:",
          "WASD - Move",
          "IJKL - Cast spells",
          "Esc - Return to stage select",
        ],
        pos=vec(400, 0),
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

import typetraits

defineSystem:
  proc updateStageSelectMenu*(input: InputManager, stageData: var StageData) =
    entities.forComponents entity, [
      LevelMenu, levelMenu,
    ]:
      if levelMenu.menu == nil:
        levelMenu.menu = levelMenuNode(addr stageData)
      levelMenu.menu.update(input)
