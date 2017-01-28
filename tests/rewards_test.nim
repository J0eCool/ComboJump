import unittest

import
  spells/runes,
  system/update_rewards,
  notifications,
  player_stats,
  rewards,
  spell_creator

suite "Rewards":
  setup:
    var
      stats = newPlayerStats()
      notifications = newN10nManager()
      spellData = newSpellData()

  template runUpdate() = 
    discard updateN10nManager(@[], notifications)
    discard updateRewards(@[], notifications, stats, spellData)

  template queueReward(toQueue: Reward) =
    add(notifications, N10n(kind: gainReward, reward: toQueue))

  test "XP Rewards":
    check stats.xp == 0
    queueReward(Reward(kind: rewardXp, amount: 3))
    runUpdate()
    check stats.xp == 3

  test "Multiple Rewards":
    check stats.xp == 0
    queueReward(Reward(kind: rewardXp, amount: 3))
    queueReward(Reward(kind: rewardXp, amount: 2))
    runUpdate()
    check stats.xp == 5

  test "Rune Rewards":
    check spellData.getCapacity(grow) == 0
    queueReward(Reward(kind: rewardRune, rune: grow))
    runUpdate()
    check spellData.getCapacity(grow) == 1
