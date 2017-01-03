import
  component/health,
  entity,
  player_stats

type XpOnDeath* = ref object of Component
  xp*: int

proc onRemoveXpOnDeath*(entity: Entity, stats: var PlayerStats) =
  entity.withComponent XpOnDeath, xpOnDeath:
    stats.addXp(xpOnDeath.xp)
