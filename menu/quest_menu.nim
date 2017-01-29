import
  sdl2

import
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

proc questMenuNode(questData: ptr QuestData, notifications: ptr N10nManager): Node =
  List[Quest](
    pos: vec(850, 300),
    spacing: vec(5),
    items: (proc(): seq[Quest] = questData[].activeQuests),
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
        color: color(128, 128, 128, 255),
        children: @[
          BorderedTextNode(
            text: info.name,
            pos: vec(0, -30),
          ),
          List[Requirement](
            items: (proc(): seq[Requirement] = quest.requirements),
            listNodes: (proc(req: Requirement): Node =
              BorderedTextNode(text: "- " & req.menuString)
            ),
          ),
          claimButton,
        ],
      )
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawQuestMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      QuestMenu, questMenu,
    ]:
      renderer.draw(questMenu.menu, resources)

defineSystem:
  proc updateQuestMenu*(input: InputManager, questData: var QuestData, notifications: var N10nManager) =
    entities.forComponents entity, [
      QuestMenu, questMenu,
    ]:
      if questMenu.menu == nil:
        questMenu.menu = questMenuNode(addr questData, addr notifications)
      questMenu.menu.update(input)
