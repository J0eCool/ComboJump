import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  input,
  menu,
  program,
  vec

type
  Building = object
    name: string
    income: float
    amount: int
    baseCost: int

proc cost(building: Building): int =
  building.baseCost

type
  AutoClickerGame* = ref object of Game
    buildings: seq[Building]
    gold: int
    partial: float
  AutoClickerController = ref object of Controller

proc totalIncome(game: AutoClickerGame): float =
  for building in game.buildings:
    result += building.income * building.amount.float

proc gameView(game: AutoClickerGame, controller: AutoClickerController): Node {.procvar.} =
  nodes(@[
    BorderedTextNode(
      pos: vec(100, 50),
      text: "Gold: " & $game.gold,
    ),
    BorderedTextNode(
      pos: vec(100, 90),
      text: "Income: " & $game.totalIncome & "/s",
    ),
    List[Building](
      pos: vec(800, 50),
      spacing: vec(10),
      items: game.buildings,
      listNodesIdx: (proc(building: Building, idx: int): Node =
        let
          cost = building.cost
          onClick =
            if game.gold < cost:
              nil
            else:
              (proc() =
                game.gold -= cost
                game.buildings[idx].amount += 1
              )
        Button(
          size: vec(200, 50),
          label: $building.amount & " - " & building.name & " : " & $cost & "G",
          onClick: onClick,
        )
      ),
    ),
  ])

proc gameUpdate(game: AutoClickerGame, controller: AutoClickerController,
                dt: float, input: InputManager) {.procvar.} =
  game.partial += dt * game.totalIncome
  game.gold += game.partial.round.int
  game.partial -= game.partial.round

proc newGameMenu(game: AutoClickerGame): Menu[AutoClickerGame, AutoClickerController] =
  Menu[AutoClickerGame, AutoClickerController](
    model: game,
    view: gameView,
    update: gameUpdate,
    controller: AutoClickerController(),
  )

proc newAutoClickerGame*(screenSize: Vec): AutoClickerGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "Auto Clicker"
  result.buildings = @[
    Building(
      name: "Hut",
      income: 0.5,
      baseCost: 10,
    ),
    Building(
      name: "House",
      income: 2,
      baseCost: 50,
    ),
  ]
  result.buildings[0].amount = 1

method loadEntities*(game: AutoClickerGame) =
  game.entities = @[]
  game.menus.push newGameMenu(game)

method draw*(renderer: RendererPtr, game: AutoClickerGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: AutoClickerGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newAutoClickerGame(screenSize), screenSize)
