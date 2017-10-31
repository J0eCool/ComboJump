import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/collider,
  quick_shoot/[
    title_screen,
  ],
  game,
  menu,
  program,
  vec


type QuickShootGame* = ref object of Game

proc newQuickShootGame*(screenSize: Vec): QuickShootGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "Quick Shooter"

method loadEntities*(game: QuickShootGame) =
  game.entities = @[]
  game.menus.push newTitleMenu()

method draw*(renderer: RendererPtr, game: QuickShootGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: QuickShootGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newQuickShootGame(screenSize), screenSize)
