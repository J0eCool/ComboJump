import tables

import
  component/enemy_stats,
  spells/runes,
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
  Requirement* = object
    info: RequirementInfo
    progress: int

  QuestInfo* = object
    id*: string
    prerequisite*: string
    name*: string
    requirements*: seq[RequirementInfo]
    rewards*: seq[Reward]

  Quest* = object
    info*: QuestInfo
    isComplete: bool
    requirements*: seq[Requirement]

  QuestData* = object
    quests: seq[Quest]

proc fromJSON*(req: var Requirement, json: JSON) =
  assert json.kind == jsObject
  req.progress.fromJSON(json.obj["progress"])
proc toJSON*(req: Requirement): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["progress"] = req.progress.toJSON()

proc fromJSON*(quest: var Quest, json: JSON) =
  assert json.kind == jsObject
  quest.isComplete.fromJSON(json.obj["isComplete"])
  let requirements = json.obj["requirements"]
  assert requirements.kind == jsArray
  assert requirements.arr.len == quest.requirements.len
  for i in 0..<quest.requirements.len:
    quest.requirements[i].fromJSON(requirements.arr[i])
proc toJSON*(quest: Quest): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["isComplete"] = quest.isComplete.toJSON()
  result.obj["requirements"] = quest.requirements.toJSON()

proc fromJSON*(questData: var QuestData, json: JSON) =
  assert json.kind == jsObject
  let questList = json.obj["quests"]
  assert questList.kind == jsObject
  for quest in questData.quests.mitems:
    quest.fromJSON(questList.obj[quest.info.id])
proc toJSON*(questData: QuestData): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  var questTable = initTable[string, JSON]()
  for quest in questData.quests:
    questTable[quest.info.id] = quest.toJSON()
  result.obj["quests"] = JSON(kind: jsObject, obj: questTable)

proc questDataWithQuests(infos: seq[QuestInfo]): QuestData =
  var quests = newSeq[Quest]()
  for info in infos:
    var quest = Quest(info: info, requirements: @[])
    for req in info.requirements:
      quest.requirements.add Requirement(info: req)
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

proc menuString*(req: Requirement): string =
  let progress = $req.progress & "/" & $req.info.count
  case req.info.kind
  of killEnemies:
    "Kill " & $req.info.count & " " & $req.info.enemyKind & "s : " & progress

template questForId(questData: QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests:
    if binding.info.id == questId:
      body

template mquestForId(questData: var QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests.mitems:
    if binding.info.id == questId:
      body

proc hasRequirementOfKind(quest: Quest, kind: RequirementKind): bool =
  for req in quest.requirements:
    if req.info.kind == kind:
      return true
  return false

proc isActive(quest: Quest, questData: QuestData): bool =
  if quest.isComplete:
    return false
  if quest.info.prerequisite != nil:
    questData.questForId quest.info.prerequisite, prereq:
      return prereq.isComplete
    assert false, "Quest id=" & quest.info.id & ", no prerequisite: " & quest.info.prerequisite
  return true

iterator mactiveQuestsWithRequirementsOfKind(questData: var QuestData, kind: RequirementKind): var Quest =
  for quest in questData.quests.mitems:
    if quest.isActive(questData) and quest.hasRequirementOfKind(kind):
      yield quest

proc isClaimable*(quest: Quest): bool =
  if quest.isComplete:
    return false
  for req in quest.requirements:
    if req.progress < req.info.count:
      return false
  return true

proc isClaimable*(questData: QuestData, id: string): bool =
  result = false
  questData.questForId id, quest:
    result = quest.isClaimable

proc claimQuest*(questData: var QuestData, id: string, notifications: var N10nManager) =
  questData.mquestForId id, quest:
    if quest.isClaimable and (not quest.isComplete):
      log "Quests", debug, "Claiming quest ", id
      quest.isComplete = true
      for reward in quest.info.rewards:
        notifications.add N10n(
          kind: gainReward,
          reward: reward,
        )

proc activeQuests*(questData: QuestData): seq[Quest] =
  result = @[]
  for quest in questData.quests:
    if quest.isActive(questData):
      result.add quest

defineSystem:
  proc updateQuests*(questData: var QuestData, notifications: var N10nManager) =
    log "Quests", debug, "Updating quests"
    for n10n in notifications.get(entityKilled):
      log "Quests", debug, "Got entityKilled notification for ", n10n.entity
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats == nil:
        continue
      let enemyKind = enemyStats.kind
      for quest in questData.mactiveQuestsWithRequirementsOfKind(killEnemies):
        for req in quest.requirements.mitems:
          if req.info.kind == killEnemies and enemyKind == req.info.enemyKind:
            log "Quests", debug, "Increasing count for quest ", quest
            req.progress += 1
    log "Quests", debug, "Done updating quests"

proc newQuestData*(): QuestData =
  #TODO: actual data
  questDataWithQuests(@[
    QuestInfo(
      id: "killThreeGoblins",
      name: "Test goblins",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 3, enemyKind: goblin),
      ],
      rewards: @[
        Reward(kind: rewardXp, amount: 100),
      ],
    ),
    QuestInfo(
      id: "killMore",
      name: "Kill more stuff",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 3, enemyKind: ogre),
        RequirementInfo(kind: killEnemies, count: 5, enemyKind: goblin),
      ],
      rewards: @[
        Reward(kind: rewardRune, rune: num),
        Reward(kind: rewardRune, rune: createSpread),
      ],
    ),
  ])
