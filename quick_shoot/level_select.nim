import
  quick_shoot/[
    # inventory_menu,
    # level,
    entity_menu,
    shooter_stats,
    shop_menu,
  ],
  menu,
  transition,
  vec


type
  Level = object
    name: string
  LevelSelect = ref object of RootObj
    levels: seq[Level]
  LevelSelectController = ref object of Controller
    stats: ShooterStats

proc newLevelSelect(): LevelSelect =
  LevelSelect(
    levels: @[
      Level(name: "Level 1"),
      Level(name: "Level 2"),
      Level(name: "Level 3?"),
    ],
  )

proc newLevelSelectController(): LevelSelectController =
  LevelSelectController(
    stats: newShooterStats(),
  )

proc levelSelectView(levels: LevelSelect, controller: LevelSelectController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Level Select",
        fontSize: 32,
      ),
      Button(
        pos: vec(800, 300),
        size: vec(200, 60),
        label: "Shop",
        onClick: (proc() =
          let shop = downcast(newShopMenu(controller.stats))
          controller.queueMenu downcast(newTransitionMenu(shop))
        ),
      ),
      Button(
        pos: vec(800, 365),
        size: vec(200, 60),
        label: "Inventory",
        # onClick: (proc() =
        #   let inventoryMenu = downcast(newInventoryMenu(controller.stats))
        #   controller.queueMenu downcast(newTransitionMenu(inventoryMenu))
        # ),
      ),
      List[Level](
        pos: vec(200, 300),
        spacing: vec(5),
        items: levels.levels,
        listNodes: (proc(level: Level): Node =
          Button(
            size: vec(200, 60),
            label: level.name,
            onClick: (proc() =
              let battleMenu = downcast(newEntityMenu(controller.stats))
              controller.queueMenu downcast(newTransitionMenu(battleMenu))
            ),
          ),
        ),
      ),
    ],
  )

proc newLevelSelectMenu*(): Menu[LevelSelect, LevelSelectController] =
  Menu[LevelSelect, LevelSelectController](
    model: newLevelSelect(),
    view: levelSelectView,
    controller: newLevelSelectController(),
  )
