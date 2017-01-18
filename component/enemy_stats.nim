import math

import
  component/[
    enemy_attack,
    health,
  ],
  entity,
  event,
  game_system,
  notifications,
  player_stats

type EnemyStats* = ref object of Component
  name*: string
  level*: int
  xp*: int
  didInit: bool

proc multiply[T](level: int, stat: T, linear: float): T =
  let
    bonus = linear * (level - 1).float
    multiplier = 1 + bonus
    raw = stat.float * multiplier
  T(raw.round)

template multiplyDamage(level: int, damage: untyped) =
  damage = multiply(level, damage, 0.075)

template multiplyHealth(level: int, health: untyped) =
  health = multiply(level, health, 0.175)

template multiplyXp(level: int, xp: untyped) =
  xp = multiply(level, xp, 0.1)

defineSystem:
  components = [EnemyStats, EnemyAttack, Health]
  proc initEnemyStats*() =
    if not enemyStats.didInit:
      enemyStats.didInit = true
      let level = enemyStats.level
      level.multiplyHealth(health.max)
      level.multiplyDamage(enemyAttack.damage)
      level.multiplyXp(enemyStats.xp)
      health.cur = health.max

defineSystem:
  proc updateEnemyStatsN10ns*(notifications: N10nManager, stats: var PlayerStats) =
    for n10n in notifications.get(entityKilled):
      let enemyStats = n10n.entity.getComponent(EnemyStats)
      if enemyStats != nil:
        stats.addXp(enemyStats.xp)
