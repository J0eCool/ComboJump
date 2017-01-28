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
      reward: Reward(kind: rewardXp, amount: 5),
    ),
    QuestInfo(
      id: "killThreeGoblins",
      requirements: @[
        RequirementInfo(kind: killEnemies, count: 3, enemyKind: goblin),
      ],
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
    check (not quests.isComplete("killOneGoblin"))
    updateKillFrame(numDead=1)
    check quests.isComplete("killOneGoblin")

  test "Long quest doesn't count as complete until satisfied":
    updateKillFrame(numDead=1)
    check (not quests.isComplete("killThreeGoblins"))

  test "Multiple counts complete long quest":
    updateKillFrame(numDead=3)
    check quests.isComplete("killThreeGoblins")

  test "Multiple counts can complete over multiple frames":
    for i in 0..<3:
      updateKillFrame(numDead=1)
    check quests.isComplete("killThreeGoblins")

  test "Too many counts complete long quest":
    updateKillFrame(numDead=100)
    check quests.isComplete("killThreeGoblins")

  test "Completing quest gives reward":
    updateKillFrame(numDead=1)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 1

  test "Not completing quest gives no reward":
    updateKillFrame()
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 0

  test "Completing quest twice gives no reward":
    updateKillFrame(numDead=1)
    updateKillFrame(numDead=1)
    discard updateN10nManager(@[], notifications)
    check notifications.get(gainReward).len == 0

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
