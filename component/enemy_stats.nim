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

defineSystem:
  proc updateEnemyStatsN10ns*(notifications: N10nManager, stats: var PlayerStats) =
    for n10n in notifications.get(entityKilled):
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats != nil:
        stats.addXp(enemyStats.xp)
