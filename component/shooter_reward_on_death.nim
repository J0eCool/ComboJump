import
  quick_shoot/[
    shooter_stats,
  ],
  entity,
  event,
  game_system,
  notifications,
  vec

type
  ShooterRewardOnDeathObj* = object of Component
    gold*: int
    xp*: int
  ShooterRewardOnDeath* = ref ShooterRewardOnDeathObj

defineComponent(ShooterRewardOnDeath, @[])

defineSystem:
  proc updateShooterRewardOnDeath*(notifications: N10nManager, stats: ShooterStats) =
    for n10n in notifications.get(entityKilled):
      let entity = n10n.entity
      entity.withComponent ShooterRewardOnDeath, reward:
        stats.addXp(reward.xp)
        stats.addGold(reward.gold)
