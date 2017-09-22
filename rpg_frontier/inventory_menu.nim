import sequtils

import
  rpg_frontier/[
    damage,
    element,
    player_stats,
    transition,
  ],
  color,
  menu,
  util,
  vec


type
  Inventory = ref object of RootObj
    stats: PlayerStats
  InventoryController = ref object of Controller
    bufferClose: bool

type Weapon = object
  name: string
  damage: Damage

proc newInventory(stats: PlayerStats): Inventory =
  Inventory(
    stats: stats,
  )

proc newInventoryController(): InventoryController =
  InventoryController()

method pushMenus(controller: InventoryController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]

proc inventoryUpdate(model: Inventory, controller: InventoryController, dt: float) {.procvar.} =
  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false

proc inventoryView(model: Inventory, controller: InventoryController): Node {.procvar.} =
  let stats = model.stats
  nodes(@[
    BorderedTextNode(
      pos: vec(600, 150),
      text: "Inventory",
      fontSize: 32,
    ),
    Button(
      pos: vec(100, 150),
      size: vec(90, 60),
      label: "Back",
      onClick: (proc() =
        controller.bufferClose = true
      ),
    ),
    BorderedTextNode(
      pos: vec(600, 300),
      text: "Current: " & $stats.damage,
    ),
    List[Weapon](
      pos: vec(200, 500),
      spacing: vec(5),
      items: @[
        Weapon(
          name: "Sword",
          damage: singleDamage(physical, 4, 50),
        ),
        Weapon(
          name: "Axe",
          damage: singleDamage(physical, 5, 30),
        ),
        Weapon(
          name: "Dagger",
          damage: singleDamage(physical, 3, 75),
        ),
      ],
      listNodes: (proc(weapon: Weapon): Node =
        Button(
          size: vec(800, 50),
          label: weapon.name & ": " & $weapon.damage,
          onClick: (proc() =
            stats.damage = weapon.damage
          ),
        ),
      ),
    ),
  ])

proc newInventoryMenu*(stats: PlayerStats): Menu[Inventory, InventoryController] =
  Menu[Inventory, InventoryController](
    model: newInventory(stats),
    view: inventoryView,
    update: inventoryUpdate,
    controller: newInventoryController(),
  )
