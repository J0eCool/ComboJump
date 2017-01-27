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

  QuestRuntime = object
    info: QuestInfo
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
  let requirements = json.obj["requirements"]
  assert requirements.kind == jsArray
  assert requirements.arr.len == quest.requirements.len
  for i in 0..<quest.requirements.len:
    quest.requirements[i].fromJSON(requirements.arr[i])
proc toJSON*(quest: QuestRuntime): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
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
proc `==`*(a, b: QuestData): bool =
  if a.quests.len != b.quests.len:
    return false
  for i in 0..<a.quests.len:
    if a.quests[i] != b.quests[i]:
      return false
  return true

proc questForId(quests: QuestData, id: string): Option[QuestRuntime] =
  for quest in quests.quests:
    if quest.info.id == id:
      return makeJust(quest)

iterator mrequirementsOfKind(quests: var QuestData, kind: RequirementKind): var RequirementRuntime =
  for quest in quests.quests.mitems:
    for req in quest.requirements.mitems:
      if req.info.kind == kind:
        yield req

proc isComplete*(quests: QuestData, id: string): bool =
  result = false
  quests.questForId(id).bindAs quest:
    result = true
    for req in quest.requirements:
      if req.progress < req.info.count:
        result = false

defineSystem:
  proc updateQuests*(quests: var QuestData, notifications: N10nManager) =
    log "Quests", debug, "Updating quests"
    for n10n in notifications.get(entityKilled):
      log "Quests", debug, "Got entityKilled notification for ", n10n.entity
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats == nil:
        continue
      let enemyKind = enemyStats.kind
      for req in quests.mrequirementsOfKind(killEnemies):
        if enemyKind == req.info.enemyKind:
          req.progress += 1
    log "Quests", debug, "Done updating quests"

proc newQuestData*(): QuestData =
  #TODO: actual data
  questDataWithQuests(@[])
