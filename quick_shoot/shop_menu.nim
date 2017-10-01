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

proc newShopController(stats: ShooterStats): ShopController =
  ShopController(
    stats: stats,
  )

type ShopItem = object
  label: string
  cost: int
  onBuy: proc()

proc `==`(a, b: ShopItem): bool =
  a.label == b.label and a.cost == b.cost

proc shopNodes(pos: Vec, stats: ShooterStats, weapon: ptr ShooterWeapon): Node =
  nodes(@[
    BorderedTextNode(text: weapon.name, pos: pos),
    List[ShopItem](
      pos: pos + vec(0, 30),
      spacing: vec(0, 50),
      listNodes: (proc(item: ShopItem): Node =
        nodes(@[
          BorderedTextNode(
            text: item.label,
            fontSize: 14,
          ),
          Button(
            pos: vec(140, 0),
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
          label: "Damage: " & $weapon.damage,
          cost: 10,
          onBuy: (proc() =
            weapon.damage += 1
          ),
        ),
        ShopItem(
          label: "Attack Speed: " & $weapon.attackSpeed,
          cost: 20,
          onBuy: (proc() =
            weapon.attackSpeed += 0.2
          ),
        ),
        ShopItem(
          label: "Bullets: " & $weapon.numBullets,
          cost: 50,
          onBuy: (proc() =
            weapon.numBullets += 1
          ),
        ),
      ],
    ),
  ])

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
      shopNodes(vec(200, 300), stats, addr stats.leftClickWeapon),
      shopNodes(vec(500, 300), stats, addr stats.qWeapon),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "Back").Node],
        onClick: (proc() =
          controller.popWithTransition()
        ),
      ),
    ],
  )

proc newShopMenu*(stats: ShooterStats): Menu[Shop, ShopController] =
  Menu[Shop, ShopController](
    model: Shop(),
    view: shopView,
    controller: newShopController(stats),
  )
