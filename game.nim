import math, sdl2

import entity, input, vec
import component/movement,
       component/player_control,
       component/sprite,
       component/transform
import system/render,
       system/physics,
       system/player_input,
       system/player_movement

type Game = ref object
  input: InputManager
  isRunning*: bool
  entities: seq[Entity]

proc newGame*(): Game =
  let
    player = newEntity(@[
      Transform(pos: vec(30, 30),
                size: vec(20, 80)),
      Movement(),
      PlayerControl(),
      Sprite(color: color(12, 255, 12, 255)),
    ])
    box = newEntity(@[
      Transform(pos:vec(400, 240),
                size: vec(60, 60)),
      Sprite(color: color(255, 16, 24, 255)),
    ])
  Game(
    input: newInputManager(),
    isRunning: true,
    entities: @[player, box]
  )

proc draw*(render: RendererPtr, game: Game) =
  render.setDrawColor(110, 132, 174)
  render.clear()

  renderSystem(game.entities, render)

  render.present()

proc update*(game: var Game, dt: float) =
  game.input.update()
  if game.input.isPressed(Input.exit):
    game.isRunning = false
  if game.input.isPressed(Input.restart):
    let input = game.input
    game = newGame()
    game.input = input

  playerInput(game.entities, game.input)
  playerMovement(game.entities, dt)
  physics(game.entities, dt)

