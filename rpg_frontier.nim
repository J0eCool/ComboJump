import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/collider,
  rpg_frontier/[
    title_screen,
  ],
  game,
  menu,
  program,
  vec


type RpgFrontierGame* = ref object of Game
  menu: Node

proc newRpgFrontierGame*(screenSize: Vec): RpgFrontierGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "RPG Frontier"

method loadEntities*(game: RpgFrontierGame) =
  game.entities = @[]
  game.menus.push newTitleMenu()

method draw*(renderer: RendererPtr, game: RpgFrontierGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: RpgFrontierGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRpgFrontierGame(screenSize), screenSize)
