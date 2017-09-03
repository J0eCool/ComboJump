import
  rpg_frontier/[
    skill_id,
  ]

type
  PlayerStats* = ref object of RootObj
    xp*: int
    skills*: seq[SkillID]

proc newPlayerStats*(): PlayerStats =
  PlayerStats(
    skills: @[scorch, chill, doubleHit],
  )

proc addXp*(stats: PlayerStats, xpGained: int) =
  stats.xp += xpGained
