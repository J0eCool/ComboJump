import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  menu/[
    title_menu,
  ],
  quick_shoot/[
    level_select,
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
  game.menus.push newTitleMenu("Quick Shooter", (proc(): MenuBase =
    downcast(newLevelSelectMenu())
  ))

method draw*(renderer: RendererPtr, game: QuickShootGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: QuickShootGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newQuickShootGame(screenSize), screenSize)
