import math

import
  entity,
  event,
  notifications,
  player_stats,
  system

type EnemyStats* = ref object of Component
  name*: string
  level*: int
  xp*: int

proc multiply(level, stat: int, linear: float): int =
  let
    bonus = linear * (level - 1).float
    multiplier = 1 + bonus
    raw = stat.float * multiplier
  raw.round.int

proc multiplyDamage*(level, damage: int): int =
  multiply(level, damage, 0.075)

proc multiplyHealth*(level, health: int): int =
  multiply(level, health, 0.175)

proc multiplyXp*(level, xp: int): int =
  multiply(level, xp, 0.1)

defineSystem:
  proc updateEnemyStatsN10ns*(notifications: N10nManager, stats: var PlayerStats) =
    for n10n in notifications.get(entityKilled):
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats != nil:
        stats.addXp(enemyStats.xp)
