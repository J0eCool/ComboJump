import unittest

import
  component/[
    enemy_stats,
    health,
  ],
  areas,
  enemy_kind,
  entity,
  notifications,
  quests,
  util

proc numEnemies(numDead = 0, numAlive = 0): Entities =
  result = @[]
  for i in 0..<(numDead + numAlive):
    result.add newEntity("Goblin " & $i, [
      EnemyStats(kind: goblin),
      newHealth(if i < numDead: 0 else: 10),
    ])

suite "QuestInfo":
  setup:
    var
      quests = newTestQuestData(@[
        QuestInfo(
          id: "killOneGoblin",
          requirements: @[
            RequirementInfo(kind: killEnemies, count: 1, enemyKind: goblin),
          ],
        ),
        QuestInfo(
          id: "killThreeGoblins",
          requirements: @[
            RequirementInfo(kind: killEnemies, count: 3, enemyKind: goblin),
          ],
        ),
      ])
      notifications = newN10nManager()

  template updateKillFrame(numDead = 0, numAlive = 0): untyped =
    discard updateHealth(numEnemies(numDead, numAlive), notifications)
    discard updateN10nManager(@[], notifications)
    discard updateQuests(@[], quests, notifications)

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
