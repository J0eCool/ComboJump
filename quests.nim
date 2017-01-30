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
  QuestStepKind* = enum
    killEnemies
  QuestStepInfo* = object
    count*: int
    case kind*: QuestStepKind
    of killEnemies:
      enemyKind*: EnemyKind
  QuestStep* = object
    info: QuestStepInfo
    progress: int

  QuestInfo* = object
    id*: string
    prerequisite*: string
    name*: string
    steps*: seq[QuestStepInfo]
    rewards*: seq[Reward]

  Quest* = object
    info*: QuestInfo
    isComplete: bool
    steps*: seq[QuestStep]

  QuestData* = object
    quests: seq[Quest]

proc fromJSON*(step: var QuestStep, json: JSON) =
  assert json.kind == jsObject
  step.progress.fromJSON(json.obj["progress"])
proc toJSON*(step: QuestStep): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["progress"] = step.progress.toJSON()

proc fromJSON*(quest: var Quest, json: JSON) =
  assert json.kind == jsObject
  quest.isComplete.fromJSON(json.obj["isComplete"])
  let steps = json.obj["steps"]
  assert steps.kind == jsArray
  assert steps.arr.len == quest.steps.len
  for i in 0..<quest.steps.len:
    quest.steps[i].fromJSON(steps.arr[i])
proc toJSON*(quest: Quest): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["isComplete"] = quest.isComplete.toJSON()
  result.obj["steps"] = quest.steps.toJSON()

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
    var quest = Quest(info: info, steps: @[])
    for step in info.steps:
      quest.steps.add QuestStep(info: step)
    quests.add quest
  QuestData(
    quests: quests,
  )

proc newTestQuestData*(testQuests: seq[QuestInfo]): QuestData =
  questDataWithQuests(testQuests)

proc `==`(a, b: QuestStepInfo): bool =
  if not (a.kind == b.kind and a.count == b.count):
    return false
  case a.kind:
  of killEnemies:
    a.enemyKind == b.enemyKind
proc `==`(a, b: QuestInfo): bool =
  a.id == b.id and a.steps == b.steps
proc `==`*(a, b: QuestData): bool =
  if a.quests.len != b.quests.len:
    return false
  for i in 0..<a.quests.len:
    if a.quests[i] != b.quests[i]:
      return false
  return true

proc menuString*(step: QuestStep): string =
  let progress = $step.progress & "/" & $step.info.count
  case step.info.kind
  of killEnemies:
    "Kill " & $step.info.count & " " & $step.info.enemyKind & "s : " & progress

template questForId(questData: QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests:
    if binding.info.id == questId:
      body

template mquestForId(questData: var QuestData, questId: string, binding, body: untyped): untyped =
  for binding in questData.quests.mitems:
    if binding.info.id == questId:
      body

proc isActive(quest: Quest, questData: QuestData): bool =
  if quest.isComplete:
    return false
  if quest.info.prerequisite != nil:
    questData.questForId quest.info.prerequisite, prereq:
      return prereq.isComplete
    assert false, "Quest id=" & quest.info.id & ", no prerequisite: " & quest.info.prerequisite
  return true

proc hasStepOfKind(quest: Quest, kind: QuestStepKind): bool =
  for req in quest.steps:
    if req.info.kind == kind:
      return true
  return false

iterator mactiveQuestsWithStepsOfKind(questData: var QuestData, kind: QuestStepKind): var Quest =
  for quest in questData.quests.mitems:
    if quest.isActive(questData) and quest.hasStepOfKind(kind):
      yield quest

proc isClaimable*(quest: Quest): bool =
  if quest.isComplete:
    return false
  for req in quest.steps:
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
      for quest in questData.mactiveQuestsWithStepsOfKind(killEnemies):
        for req in quest.steps.mitems:
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
      steps: @[
        QuestStepInfo(kind: killEnemies, count: 3, enemyKind: goblin),
      ],
      rewards: @[
        Reward(kind: rewardXp, amount: 100),
      ],
    ),
    QuestInfo(
      id: "killMore",
      name: "Kill more stuff",
      steps: @[
        QuestStepInfo(kind: killEnemies, count: 3, enemyKind: ogre),
        QuestStepInfo(kind: killEnemies, count: 5, enemyKind: goblin),
      ],
      rewards: @[
        Reward(kind: rewardRune, rune: num),
        Reward(kind: rewardRune, rune: createSpread),
      ],
    ),
  ])
