import
  rpg_frontier/[
    damage,
    element,
    skill_id,
  ]

type
  PlayerStats* = ref object of RootObj
    xp*: int
    skills*: seq[SkillID]
    damage*: Damage

proc newPlayerStats*(): PlayerStats =
  PlayerStats(
    skills: @[attack, scorch, chill, doubleHit],
    damage: singleDamage(physical, 4, 60),
  )

proc addXp*(stats: PlayerStats, xpGained: int) =
  stats.xp += xpGained
