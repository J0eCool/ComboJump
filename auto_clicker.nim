import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  input,
  menu,
  percent,
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

let allBuildings: array[Building, BuildingInfo] = [
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
  Upgrade = enum
    boostTransistor
    boostTransistor2
  UpgradeInfo = object
    name: string
    target: Building
    cost: int
    boost: Percent

let allUpgrades: array[Upgrade, UpgradeInfo] = [
  boostTransistor: UpgradeInfo(
    name: "Transistor Boost",
    target: transistor,
    cost: 100,
    boost: 25.Percent,
  ),
  boostTransistor2: UpgradeInfo(
    name: "Transistor Aux Boost",
    target: transistor,
    cost: 2500,
    boost: 50.Percent,
  ),
]

type
  AutoClickerGame* = ref object of Game
    buildings: array[Building, int]
    upgrades: array[Upgrade, int]
    gold: int
    partial: float
  AutoClickerController = ref object of Controller

proc cost(game: AutoClickerGame, building: Building): int =
  allBuildings[building].cost

proc cost(game: AutoClickerGame, upgrade: Upgrade): int =
  allUpgrades[upgrade].cost

proc totalIncome(game: AutoClickerGame): float =
  for building, info in allBuildings:
    var income = info.income * game.buildings[building].float
    for upgrade, upInfo in allUpgrades:
      if upInfo.target == building:
        income = income * pow(1.0 + upInfo.boost.toFloat, game.upgrades[upgrade].float)
    result += income

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
    List[Upgrade](
      pos: vec(500, 50),
      spacing: vec(10),
      items: allOf[Upgrade](),
      listNodes: (proc(upgrade: Upgrade): Node =
        let
          info = allUpgrades[upgrade]
          cost = game.cost(upgrade)
          onClick =
            if game.gold < cost:
              nil
            else:
              (proc() =
                game.gold -= cost
                game.upgrades[upgrade] += 1
              )
        Button(
          size: vec(200, 50),
          label: $game.upgrades[upgrade] & " - " & info.name & " : " & $cost & "G",
          onClick: onClick,
        )
      ),
    ),
    List[Building](
      pos: vec(800, 50),
      spacing: vec(10),
      items: allOf[Building](),
      listNodes: (proc(building: Building): Node =
        let
          info = allBuildings[building]
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
  result.gold = 1000

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
