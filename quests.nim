import
  component/enemy_stats,
  enemy_kind,
  entity,
  event,
  game_system,
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
    isComplete: bool

  QuestData* = object
    quests: seq[QuestRuntime]

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
