import
  component/health,
  component/limited_quantity,
  entity,
  event,
  player_stats,
  system

type PlayerHealth* = ref object of Health
  didInitialize*: bool

defineSystem:
  proc updatePlayerHealth*(stats: PlayerStats) =
    entities.forComponents entity, [
      PlayerHealth, playerHealth,
    ]:
      playerHealth.max = stats.maxHealth().float
      if not playerHealth.didInitialize:
        playerHealth.didInitialize = true
        playerHealth.cur = playerHealth.max
