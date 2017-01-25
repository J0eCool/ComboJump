import
  component/health,
  component/limited_quantity,
  component/mana,
  entity,
  event,
  game_system,
  logging,
  player_stats

type
  PlayerHealth* = ref object of Health
    didInitialize*: bool
  PlayerMana* = ref object of Mana
    didInitialize*: bool

defineSystem:
  priority = 5
  components = [PlayerHealth, PlayerMana]
  proc updatePlayerHealth*(stats: PlayerStats) =
    playerHealth.max = stats.maxHealth().float
    playerMana.max = stats.maxMana().float
    log "PlayerHealth", debug, "Updating player health - entity ", entity, "; max health = ", playerHealth.max
    playerMana.regenPerSecond = stats.manaRegen()

    if not playerHealth.didInitialize:
      log "PlayerHealth", debug, "Initializing player health"
      playerHealth.didInitialize = true
      playerHealth.cur = playerHealth.max
    if not playerMana.didInitialize:
      log "PlayerHealth", debug, "Initializing player mana"
      playerMana.didInitialize = true
      playerMana.cur = playerMana.max
