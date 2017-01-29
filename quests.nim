import tables

import
  component/enemy_stats,
  enemy_kind,
  entity,
  event,
  game_system,
  jsonparse,
  logging,
  notifications,
  option,
  rewards,
  util

type
  RequirementKind* = enum
    killEnemies
  RequirementInfo* = object
    count*: int
    case kind*: RequirementKind
    of killEnemies:
      enemyKind*: EnemyKind
  RequirementRuntime = object
    info: RequirementInfo
    progress: int

  QuestInfo* = object
    id*: string
    requirements*: seq[RequirementInfo]
    reward*: Reward

  QuestRuntime = object
    info: QuestInfo
    isComplete: bool
    requirements: seq[RequirementRuntime]

  QuestData* = object
    quests: seq[QuestRuntime]

proc fromJSON*(req: var RequirementRuntime, json: JSON) =
  assert json.kind == jsObject
  req.progress.fromJSON(json.obj["progress"])
proc toJSON*(req: RequirementRuntime): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["progress"] = req.progress.toJSON()

proc fromJSON*(quest: var QuestRuntime, json: JSON) =
  assert json.kind == jsObject
  quest.isComplete.fromJSON(json.obj["isComplete"])
  let requirements = json.obj["requirements"]
  assert requirements.kind == jsArray
  assert requirements.arr.len == quest.requirements.len
  for i in 0..<quest.requirements.len:
    quest.requirements[i].fromJSON(requirements.arr[i])
proc toJSON*(quest: QuestRuntime): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["isComplete"] = quest.isComplete.toJSON()
  result.obj["requirements"] = quest.requirements.toJSON()

proc fromJSON*(quests: var QuestData, json: JSON) =
  assert json.kind == jsObject
  let questList = json.obj["quests"]
  assert questList.kind == jsObject
  for quest in quests.quests.mitems:
    quest.fromJSON(questList.obj[quest.info.id])
proc toJSON*(quests: QuestData): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  var questTable = initTable[string, JSON]()
  for quest in quests.quests:
    questTable[quest.info.id] = quest.toJSON()
  result.obj["quests"] = JSON(kind: jsObject, obj: questTable)

proc questDataWithQuests(infos: seq[QuestInfo]): QuestData =
  var quests = newSeq[QuestRuntime]()
  for info in infos:
    var quest = QuestRuntime(info: info, requirements: @[])
    for req in info.requirements:
      quest.requirements.add RequirementRuntime(info: req)
    quests.add quest
  QuestData(
    quests: quests,
  )

proc newTestQuestData*(testQuests: seq[QuestInfo]): QuestData =
  questDataWithQuests(testQuests)

proc `==`(a, b: RequirementInfo): bool =
  if not (a.kind == b.kind and a.count == b.count):
    return false
  case a.kind:
  of killEnemies:
    a.enemyKind == b.enemyKind
proc `==`(a, b: QuestInfo): bool =
  a.id == b.id and a.requirements == b.requirements
proc `==`*(a, b: QuestData): bool =
  if a.quests.len != b.quests.len:
    return false
  for i in 0..<a.quests.len:
    if a.quests[i] != b.quests[i]:
      return false
  return true

template questForId(questData: QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests:
    if binding.info.id == questId:
      body

template mquestForId(questData: var QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests.mitems:
    if binding.info.id == questId:
      body

iterator mquestsWithRequirementsOfKind(quests: var QuestData, kind: RequirementKind): var QuestRuntime =
  for quest in quests.quests.mitems:
    for req in quest.requirements.mitems:
      if req.info.kind == kind:
        yield quest
        break

proc isClaimable(quest: QuestRuntime): bool =
  for req in quest.requirements:
    if req.progress < req.info.count:
      return false
  return true

proc isClaimable*(quests: QuestData, id: string): bool =
  result = false
  quests.questForId id, quest:
    result = quest.isComplete

proc claimQuest*(quests: var QuestData, id: string, notifications: var N10nManager) =
  quests.mquestForId id, quest:
    if quest.isClaimable and (not quest.isComplete):
      log "Quests", debug, "Claiming quest ", id
      quest.isComplete = true
      notifications.add N10n(kind: gainReward, reward: quest.info.reward)

defineSystem:
  proc updateQuests*(quests: var QuestData, notifications: var N10nManager) =
    log "Quests", debug, "Updating quests"
    for n10n in notifications.get(entityKilled):
      log "Quests", debug, "Got entityKilled notification for ", n10n.entity
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats == nil:
        continue
      let enemyKind = enemyStats.kind
      for quest in quests.mquestsWithRequirementsOfKind(killEnemies):
        if not quest.isComplete:
          for req in quest.requirements.mitems:
            if req.info.kind == killEnemies and enemyKind == req.info.enemyKind:
              req.progress += 1
          if quest.isClaimable:
            claimQuest(quests, quest.info.id, notifications)
    log "Quests", debug, "Done updating quests"

proc newQuestData*(): QuestData =
  #TODO: actual data
  questDataWithQuests(@[])
