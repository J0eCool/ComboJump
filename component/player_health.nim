import
  component/health,
  component/limited_quantity,
  component/mana,
  entity,
  event,
  game_system,
  player_stats

type
  PlayerHealth* = ref object of Health
    didInitialize*: bool
  PlayerMana* = ref object of Mana
    didInitialize*: bool

defineSystem:
  components = [PlayerHealth, PlayerMana]
  proc updatePlayerHealth*(stats: PlayerStats) =
    playerHealth.max = stats.maxHealth().float
    playerMana.max = stats.maxMana().float
    playerMana.regenPerSecond = stats.manaRegen()

    if not playerHealth.didInitialize:
      playerHealth.didInitialize = true
      playerHealth.cur = playerHealth.max
    if not playerMana.didInitialize:
      playerMana.didInitialize = true
      playerMana.cur = playerMana.max
