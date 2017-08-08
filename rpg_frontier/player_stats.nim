type
  PlayerStats* = ref object of RootObj
    xp*: int

proc newPlayerStats*(): PlayerStats =
  PlayerStats()

proc addXp*(stats: PlayerStats, xpGained: int) =
  stats.xp += xpGained
