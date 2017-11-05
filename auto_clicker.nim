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
  util,
  vec

type
  Building = enum
    transistor
    gate
    bus
  BuildingInfo = object
    name: string
    income: float
    cost: int
    amount: int

let allBuildingInfos: array[Building, BuildingInfo] = [
  transistor: BuildingInfo(
    name: "Transistor",
    income: 0.5,
    cost: 10,
  ),
  gate: BuildingInfo(
    name: "Gate",
    income: 2,
    cost: 50,
  ),
  bus: BuildingInfo(
    name: "Bus",
    income: 9,
    cost: 350,
  ),
]

type
  AutoClickerGame* = ref object of Game
    buildings: array[Building, int]
    gold: int
    partial: float
  AutoClickerController = ref object of Controller

proc cost(game: AutoClickerGame, building: Building): int =
  allBuildingInfos[building].cost

proc totalIncome(game: AutoClickerGame): float =
  for building, info in allBuildingInfos:
    result += info.income * game.buildings[building].float

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
      items: allOf[Building](),
      listNodes: (proc(building: Building): Node =
        let
          info = allBuildingInfos[building]
          cost = game.cost(building)
          onClick =
            if game.gold < cost:
              nil
            else:
              (proc() =
                game.gold -= cost
                game.buildings[building] += 1
              )
        Button(
          size: vec(200, 50),
          label: $game.buildings[building] & " - " & info.name & " : " & $cost & "G",
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
  result.buildings[transistor] = 1

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
