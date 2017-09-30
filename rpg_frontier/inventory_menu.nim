import sequtils

import
  rpg_frontier/[
    damage,
    element,
    player_stats,
  ],
  color,
  input,
  menu,
  transition,
  util,
  vec


type
  InventoryController = ref object of Controller

type Weapon = object
  name: string
  damage: Damage

proc newInventoryController(): InventoryController =
  InventoryController()

proc inventoryView(stats: PlayerStats, controller: InventoryController): Node {.procvar.} =
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
        controller.shouldPop = true
        controller.queueMenu downcast(newFadeOnlyOut())
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

proc newInventoryMenu*(stats: PlayerStats): Menu[PlayerStats, InventoryController] =
  Menu[PlayerStats, InventoryController](
    model: stats,
    view: inventoryView,
    controller: newInventoryController(),
  )
