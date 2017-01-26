import math, sdl2

import
  component/[
    enemy_attack,
    health,
    popup_text,
    transform,
  ],
  enemy_kind,
  entity,
  event,
  game_system,
  notifications,
  player_stats,
  vec

type EnemyStats* = ref object of Component
  name*: string
  kind*: EnemyKind
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
    result = @[]
    for n10n in notifications.get(entityKilled):
      let entity = n10n.entity
      entity.withComponent EnemyStats, enemyStats:
        stats.addXp(enemyStats.xp)
        entity.withComponent Transform, transform:
          let popup = newEntity("XpPopup", [
            Transform(pos: transform.pos - vec(0, 75)),
            PopupText(text: "+" & $enemyStats.xp & " XP", color: color(0, 255, 0, 255)),
          ])
          result.add event.Event(kind: addEntity, entity: popup)
