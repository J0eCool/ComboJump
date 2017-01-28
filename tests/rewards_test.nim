import unittest

import
  system/update_rewards,
  notifications,
  player_stats,
  rewards

suite "Rewards":
  test "XP Rewards work":
    var
      stats = newPlayerStats()
      notifications = newN10nManager()
    let reward = Reward(kind: rewardXp, amount: 3)
    notifications.add(N10n(kind: gainReward, reward: reward))
    discard updateN10nManager(@[], notifications)
    discard updateRewards(@[], notifications, stats)
    check stats.xp == 3
