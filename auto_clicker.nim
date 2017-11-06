import math, macros, sequtils, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  color,
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
  StrategyNodeKind = enum
    buyBuilding
  StrategyNode = object
    case kind: StrategyNodeKind
    of buyBuilding:
      building: Building
  Strategy = object
    nodes: seq[StrategyNode]

proc `==`(a, b: StrategyNode): bool =
  a.kind == b.kind and (
    case a.kind
    of buyBuilding:
      a.building == b.building
  )

type
  AutoClickerGame* = ref object of Game
    buildings: array[Building, int]
    upgrades: array[Upgrade, int]
    strategy: Strategy
    gold: int
    partialGold: float
  AutoClickerController = ref object of Controller

proc cost(game: AutoClickerGame, building: Building): int =
  allBuildings[building].cost

proc cost(game: AutoClickerGame, upgrade: Upgrade): int =
  allUpgrades[upgrade].cost

proc upgradedIncome(game: AutoClickerGame, building: Building): float =
  result = allBuildings[building].income
  for upgrade, upInfo in allUpgrades:
    if upInfo.target == building:
      result = result * pow(1.0 + upInfo.boost.toFloat, game.upgrades[upgrade].float)

proc totalIncome(game: AutoClickerGame, building: Building): float =
  game.upgradedIncome(building) * game.buildings[building].float

proc totalIncome(game: AutoClickerGame): float =
  for building in Building:
    result += game.totalIncome(building)

proc tryBuy(game: AutoClickerGame, building: Building) =
  let cost = game.cost(building)
  if game.gold >= cost:
    game.gold -= cost
    game.buildings[building] += 1

proc buildingNode(game: AutoClickerGame, building: Building): Node =
  let
    info = allBuildings[building]
    cost = game.cost(building)
    count = game.buildings[building]
    canAfford = game.gold >= cost
    onClick =
      if not canAfford:
        nil
      else:
        (proc() =
          game.tryBuy(building)
        )
  Button(
    size: vec(350, 80),
    onClick: onClick,
    children: @[
      SpriteNode(
        pos: vec(-130, 0),
        size: vec(64),
        color: if canAfford: green else: red,
      ),
      BorderedTextNode(
        pos: vec(-40, -20),
        text: info.name,
      ),
      BorderedTextNode(
        pos: vec(110, -20),
        text: $count,
      ),
      BorderedTextNode(
        pos: vec(110, 20),
        text: $cost & "G",
      ),
      BorderedTextNode(
        pos: vec(0, 5),
        text: "+" & $game.upgradedIncome(building) & "/s (each)",
        fontSize: 14,
      ),
      BorderedTextNode(
        pos: vec(0, 25),
        text: "+" & $game.totalIncome(building) & "/s (total)",
        fontSize: 14,
      ),
    ],
  )

proc upgradeNode(game: AutoClickerGame, upgrade: Upgrade): Node =
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
    size: vec(300, 50),
    label: info.name & " : " & $cost & "G",
    onClick: onClick,
  )

proc strategyNode(game: AutoClickerGame, pos: Vec): Node =
  List[StrategyNode](
    pos: pos,
    spacing: vec(10),
    items: game.strategy.nodes,
    listNodesIdx: (proc(node: StrategyNode, idx: int): Node =
      case node.kind
      of buyBuilding:
        SpriteNode(
          size: vec(400, 40),
          color: gray,
          children: @[
            BorderedTextNode(
              text: "Buy building:",
              pos: vec(-140, 0),
              fontSize: 18,
            ),
            Button(
              pos: vec(100, 0),
              size: vec(180, 36),
              label: allBuildings[node.building].name,
              color: lightRed,
              onClick: (proc() =
                let
                  i = ord(node.building)
                  j = (i + 1) mod (Building.high.ord + 1)
                  next = Building(j)
                game.strategy.nodes[idx].building = next
              ),
            ),
          ],
        )
    ),
  )

proc gameView(game: AutoClickerGame, controller: AutoClickerController): Node {.procvar.} =
  nodes(@[
    BorderedTextNode(
      pos: vec(140, 50),
      text: "Gold: " & $game.gold,
    ),
    BorderedTextNode(
      pos: vec(140, 90),
      text: "Income: " & $game.totalIncome & "/s",
    ),
    List[Upgrade](
      pos: vec(360, 50),
      spacing: vec(10),
      items: allOf[Upgrade]().filterIt(game.upgrades[it] == 0),
      listNodes: (proc(upgrade: Upgrade): Node =
        game.upgradeNode(upgrade)
      ),
    ),
    List[Building](
      pos: vec(800, 50),
      spacing: vec(10),
      items: allOf[Building](),
      listNodes: (proc(building: Building): Node =
        game.buildingNode(building)
      ),
    ),
    game.strategyNode(vec(100, 400)),
  ])

proc updateIncome(game: AutoClickerGame, dt: float) =
  game.partialGold += dt * game.totalIncome
  game.gold += game.partialGold.round.int
  game.partialGold -= game.partialGold.round

proc updateStrategy(game: AutoClickerGame) =
  for node in game.strategy.nodes:
    case node.kind
    of buyBuilding:
      game.tryBuy(node.building)

proc newGameMenu(game: AutoClickerGame): Menu[AutoClickerGame, AutoClickerController] =
  Menu[AutoClickerGame, AutoClickerController](
    model: game,
    view: gameView,
    controller: AutoClickerController(),
  )

proc newAutoClickerGame*(screenSize: Vec): AutoClickerGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "Auto Clicker"
  result.buildings[transistor] = 1
  result.strategy = Strategy(nodes: @[
    StrategyNode(kind: buyBuilding, building: transistor),
  ])

method loadEntities*(game: AutoClickerGame) =
  game.entities = @[]
  game.menus.push newGameMenu(game)

method draw*(renderer: RendererPtr, game: AutoClickerGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: AutoClickerGame, dt: float) =
  game.dt = dt

  game.updateIncome(dt)
  game.updateStrategy()

  game.menus.update(dt, game.input)

  if game.input.isPressed(Input.quit):
    echo "QUITTIN" #TODO: save here

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newAutoClickerGame(screenSize), screenSize)
