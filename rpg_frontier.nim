import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/collider,
  rpg_frontier/[
    battle,
    transition,
  ],
  camera,
  color,
  drawing,
  game,
  input,
  logging,
  menu,
  program,
  resources,
  vec,
  util

##
## TODO: put these in the right files
##


type
  TitleScreen = ref object of RootObj
  TitleScreenController = ref object of Controller
    battle: BattleData
    start: bool

method pushMenus(controller: TitleScreenController): seq[MenuBase] =
  if controller.start:
    controller.start = false
    let battleMenu = downcast(newBattleMenu(controller.battle))
    result = @[downcast(newTransitionMenu(battleMenu))]

proc mainMenuView(menu: TitleScreen, controller: TitleScreenController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "GAME TITLE",
      ),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "START").Node],
        onClick: (proc() =
          controller.start = true
        ),
      ),
    ],
  )

proc newTitleMenu(battle: BattleData): Menu[TitleScreen, TitleScreenController] =
  Menu[TitleScreen, TitleScreenController](
    model: TitleScreen(),
    view: mainMenuView,
    controller: TitleScreenController(battle: battle),
  )

##
##
##


type RpgFrontierGame* = ref object of Game
  battle: BattleData
  menu: Node

proc newRpgFrontierGame*(screenSize: Vec): RpgFrontierGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "RPG Frontier"
  result.battle = newBattleData()

method loadEntities*(game: RpgFrontierGame) =
  game.entities = @[]
  game.menus.push newTitleMenu(game.battle)

method draw*(renderer: RendererPtr, game: RpgFrontierGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: RpgFrontierGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRpgFrontierGame(screenSize), screenSize)
