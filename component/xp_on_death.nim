import
  entity,
  event,
  notifications,
  player_stats,
  system

type XpOnDeath* = ref object of Component
  xp*: int

defineSystem:
  proc updateXpOnDeathN10ns*(notifications: N10nManager, stats: var PlayerStats) =
    for n10n in notifications.get(entityKilled):
      let xpOnDeath = n10n.entity.getComponent(XpOnDeath)
      if xpOnDeath != nil:
        stats.addXp(xpOnDeath.xp)
