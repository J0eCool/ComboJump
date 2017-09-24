from sdl2 import RendererPtr

import
  color,
  input,
  entity,
  event,
  game_system,
  menu,
  notifications,
  quests,
  resources,
  vec,
  util

type
  QuestMenu* = ref object of Component
    menu: Node

defineComponent(QuestMenu)

proc questMenuNode(questData: ptr QuestData, notifications: ptr N10nManager): Node =
  List[Quest](
    pos: vec(850, 300),
    spacing: vec(5),
    items: questData[].activeQuests,
    listNodes: (proc(quest: Quest): Node =
      let
        info = quest.info
        claimButton =
          if not quest.isClaimable:
            Node()
          else:
            Button(
              pos: vec(130, 0),
              size: vec(60),
              onClick: (proc() =
                questData[].claimQuest(info.id, notifications[])
              ),
              children: newSeqOf[Node](
                BorderedTextNode(text: "Claim")
              ),
            )
      SpriteNode(
        size: vec(300, 80),
        color: rgb(128, 128, 128),
        children: @[
          BorderedTextNode(
            text: info.name,
            pos: vec(0, -30),
          ),
          List[QuestStep](
            pos: vec(0, -10),
            items: quest.steps,
            listNodes: (proc(req: QuestStep): Node =
              BorderedTextNode(
                text: "- " & req.menuString,
                size: vec(0, 24),
              )
            ),
          ),
          claimButton,
        ],
      )
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawQuestMenu*(resources: ResourceManager) =
    entities.forComponents entity, [
      QuestMenu, questMenu,
    ]:
      renderer.draw(questMenu.menu, resources)

defineSystem:
  proc updateQuestMenu*(menus: var MenuManager, input: InputManager, questData: var QuestData, notifications: var N10nManager) =
    entities.forComponents entity, [
      QuestMenu, questMenu,
    ]:
      if questMenu.menu == nil:
        questMenu.menu = questMenuNode(addr questData, addr notifications)
      questMenu.menu.update(menus, input)
