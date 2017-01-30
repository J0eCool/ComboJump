import unittest

import
  component/[
    enemy_stats,
    health,
  ],
  system/update_rewards,
  enemy_kind,
  entity,
  jsonparse,
  notifications,
  rewards,
  quests,
  util

let testQuestList = @[
    QuestInfo(
      id: "killOneGoblin",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 1, enemyKind: goblin),
      ],
      rewards: @[Reward(kind: rewardXp, amount: 5)],
    ),
    QuestInfo(
      id: "killThreeGoblins",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 3, enemyKind: goblin),
      ],
      rewards: @[
        Reward(kind: rewardXp, amount: 5),
        Reward(kind: rewardXp, amount: 5),
      ],
    ),
    QuestInfo(
      id: "killOneMoreGoblin",
      prerequisite: "killOneGoblin",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 1, enemyKind: goblin),
      ],
      rewards: @[Reward(kind: rewardXp, amount: 5)],
    ),
  ]

proc numEnemies(numDead = 0, numAlive = 0): Entities =
  result = @[]
  for i in 0..<(numDead + numAlive):
    result.add newEntity("Goblin " & $i, [
      EnemyStats(kind: goblin),
      newHealth(if i < numDead: 0 else: 10),
    ])

template updateKillFrame(numDead = 0, numAlive = 0): untyped =
  discard updateHealth(numEnemies(numDead, numAlive), notifications)
  discard updateN10nManager(@[], notifications)
  discard updateQuests(@[], quests, notifications)

suite "QuestInfo":
  setup:
    var
      quests = newTestQuestData(testQuestList)
      notifications = newN10nManager()

  test "Enemy killing trigger works":
    updateKillFrame(numDead=1)
    check quests.isClaimable("killOneGoblin")

  test "Quests aren't claimable by default":
    check (not quests.isClaimable("killOneGoblin"))

  test "Long quest doesn't count as complete until satisfied":
    updateKillFrame(numDead=1)
    check (not quests.isClaimable("killThreeGoblins"))

  test "Multiple counts complete long quest":
    updateKillFrame(numDead=3)
    check quests.isClaimable("killThreeGoblins")

  test "Multiple counts can complete over multiple frames":
    for i in 0..<3:
      updateKillFrame(numDead=1)
    check quests.isClaimable("killThreeGoblins")

  test "Too many counts complete long quest":
    for i in 0..<12:
      updateKillFrame(numDead=1)
    check quests.isClaimable("killThreeGoblins")

  test "Completing quest gives reward":
    updateKillFrame(numDead=1)
    quests.claimQuest("killOneGoblin", notifications)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 1

  test "Not claiming quest gives no reward":
    updateKillFrame(numDead=1)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 0

  test "Claiming quest makes quest no longer claimable":
    updateKillFrame(numDead=1)
    quests.claimQuest("killOneGoblin", notifications)
    check (not quests.isClaimable("killOneGoblin"))

  test "Not completing quest gives no reward":
    updateKillFrame()
    quests.claimQuest("killOneGoblin", notifications)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 0

  test "Completing quest twice gives no reward":
    updateKillFrame(numDead=1)
    quests.claimQuest("killOneGoblin", notifications)
    discard updateN10nManager(@[], notifications)
    quests.claimQuest("killOneGoblin", notifications)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 0

  test "Quests can give multiple rewards":
    updateKillFrame(numDead=3)
    quests.claimQuest("killThreeGoblins", notifications)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 2

  test "Quests with prerequisites can be unlocked":
    updateKillFrame(numDead=1)
    quests.claimQuest("killOneGoblin", notifications)
    updateKillFrame(numDead=1)
    check quests.isClaimable("killOneMoreGoblin")

  test "Quests with prerequisites don't make progress when not active":
    updateKillFrame(numDead=1)
    check (not quests.isClaimable("killOneMoreGoblin"))


suite "QuestInfo - serialization":
  setup:
    let beginQuests = newTestQuestData(testQuestList)

  test "Quest equality works":
    check beginQuests == beginQuests

  test "Roundtripping initial state":
    var endQuests = beginQuests
    endQuests.fromJSON(toJSON(beginQuests))
    check endQuests == beginQuests

  test "Roundtripping with modified state":
    var
      quests = beginQuests
      notifications = newN10nManager()
      endQuests = beginQuests
    updateKillFrame(numDead=5)
    endQuests.fromJSON(toJSON(quests))
    check endQuests == quests

  #TODO: test adding quest
  #TODO: test adding requirement to a quest
  #TODO: test changing requirement on a quest
  #TODO: test removing requirement on a quest
