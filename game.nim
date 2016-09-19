import math, sdl2

import entity, input, vec
import
  component/collider,
  component/movement,
  component/player_control,
  component/sprite,
  component/transform,
  system/collisions,
  system/physics,
  system/player_input,
  system/player_movement,
  system/render

type Game = ref object
  input: InputManager
  isRunning*: bool
  entities: seq[Entity]

proc newGame*(): Game =
  Game(
    input: newInputManager(),
    isRunning: true,
    entities: @[
      newEntity("Player", [
        Transform(pos: vec(30, 30),
                  size: vec(40, 80)),
        Movement(),
        PlayerControl(),
        Sprite(color: color(12, 255, 12, 255)),
        Collider(layer: Layer.player),
      ]),
      newEntity("Enemy", [
        Transform(pos: vec(400, 640),
                  size: vec(60, 60)),
        Sprite(color: color(155, 16, 24, 255)),
        Collider(layer: Layer.enemy),
      ]),
      newEntity("Ground", [
        Transform(pos: vec(150, 800),
                  size: vec(900, 35)),
        Sprite(color: color(192, 192, 192, 255)),
        Collider(layer: Layer.floor),
      ]),
    ],
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
  checkCollisisons(game.entities)

