import
  entity,
  event,
  game_system,
  logging,
  notifications,
  player_stats,
  rewards,
  spell_creator

defineSystem:
  proc updateRewards*(notifications: var N10nManager,
                      stats: var PlayerStats,
                      spellData: var SpellData,
                     ) =
    for n10n in notifications.get(gainReward):
      let reward = n10n.reward
      log "Rewards", debug, "Gained reward: ", reward
      case reward.kind
      of rewardXp:
        stats.addXp(reward.amount)
      of rewardRune:
        spellData.addRuneCapacity(reward.rune)
