import unittest

import
  component/player_health,
  nano_game,
  prefabs,
  vec

suite "PlayerHealth":
  test "Player doesn't instantly die":
    let
      player = newPlayer(vec(0))
      game = newTestNanoGame()
    game.entities = @[player]
    game.update(0.1)
    check:
      game.entities.len == 1
      game.entities[0] == player
