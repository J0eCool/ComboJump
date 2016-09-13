import math, sdl2

import entity, input, player, vec

type Game = ref object
  input: InputManager
  isRunning*: bool
  player: Player

proc newGame*(): Game =
  Game(
    input: newInputManager(),
    isRunning: true,
    player: newPlayer(),
  )

proc draw*(render: RendererPtr, game: Game) =
  render.setDrawColor(110, 132, 174)
  render.clear()

  # var r = rect(cint(400 + 200 * sin(t)), 20, 100, 100)
  # render.setDrawColor(64, 212, 110)
  # render.fillRect(r)

  render.draw(game.player)

  render.present()

proc update*(game: var Game, dt: float) =
  game.input.update()
  if game.input.isPressed(Input.exit):
    game.isRunning = false
  if game.input.isPressed(Input.restart):
    let input = game.input
    game = newGame()
    game.input = input

  game.player.update(dt, game.input)
