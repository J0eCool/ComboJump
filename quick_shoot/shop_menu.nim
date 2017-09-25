import
  quick_shoot/[
    entity_menu,
    shooter_stats,
  ],
  menu,
  transition,
  vec


type
  Shop = ref object of RootObj
  ShopController = ref object of Controller
    stats: ShooterStats
    start: bool

proc newShopController(): ShopController =
  ShopController(
    stats: ShooterStats(
      attackSpeed: 1.4,
      damage: 3,
      numBullets: 1,
      gold: 100,
    ),
  )

method pushMenus(controller: ShopController): seq[MenuBase] =
  if controller.start:
    controller.start = false
    let levelSelect = downcast(newEntityMenu(controller.stats))
    result = @[downcast(newTransitionMenu(levelSelect))]

type ShopItem = object
  label: string
  cost: int
  onBuy: proc()

proc `==`(a, b: ShopItem): bool =
  a.label == b.label and a.cost == b.cost

proc shopNodes(stats: ShooterStats): Node =
  List[ShopItem](
    pos: vec(200, 300),
    spacing: vec(0, 50),
    listNodes: (proc(item: ShopItem): Node =
      nodes(@[
        BorderedTextNode(text: item.label),
        Button(
          pos: vec(200, 0),
          size: vec(80, 40),
          label: $item.cost & " G",
          onClick: (proc() =
            if stats.gold >= item.cost:
              stats.gold -= item.cost
              item.onBuy()
          ),
        ),
      ])
    ),
    items: @[
      ShopItem(
        label: "Damage: " & $stats.damage,
        cost: 10,
        onBuy: (proc() =
          stats.damage += 1
        ),
      ),
      ShopItem(
        label: "Attack Speed: " & $stats.attackSpeed,
        cost: 20,
        onBuy: (proc() =
          stats.attackSpeed += 0.2
        ),
      ),
      ShopItem(
        label: "Bullets: " & $stats.numBullets,
        cost: 50,
        onBuy: (proc() =
          stats.numBullets += 1
        ),
      ),
    ],
  )

proc shopView(menu: Shop, controller: ShopController): Node {.procvar.} =
  let stats = controller.stats
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Shop",
        fontSize: 48,
      ),
      BorderedTextNode(
        pos: vec(200, 700),
        text: "G: " & $stats.gold,
      ),
      shopNodes(stats),
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

proc newShopMenu*(): Menu[Shop, ShopController] =
  Menu[Shop, ShopController](
    model: Shop(),
    view: shopView,
    controller: newShopController(),
  )
