import unittest

import
  jsonparse,
  player_stats

suite "PlayerStats":
  setup:
    var stats = newPlayerStats()
    let lotsOfXp = 1000 * stats.xpToNextLevel()

  test "Serialization":
    let
      before = PlayerStats(
        level: 7,
        xp: 126,
      )
      json = before.toJson()
      after = fromJson[PlayerStats](json)
    check before == after

  test "Sanity - new stats start at level 1":
    check stats.level == 1

  test "Level up when gaining exactly enough xp":
    stats.addXp(stats.xpToNextLevel())
    check stats.level == 2

  test "Level up multiple times with one call to addXp":
    stats.addXp(lotsOfXp)
    check stats.level > 2

  test "Xp is reduced after leveling up":
    stats.addXp(lotsOfXp)
    check stats.xp < lotsOfXp
