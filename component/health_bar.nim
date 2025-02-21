from sdl2 import RendererPtr

import
  component/[
    enemy_stats,
    health,
    limited_quantity,
    transform,
  ],
  camera,
  color,
  entity,
  event,
  game_system,
  input,
  menu,
  resources,
  vec,
  util

type
  HealthBar* = ref object of Component
    menu: Node
  HealthPair* = tuple[cur: int, max: int]
  HealthPairProc = proc(): HealthPair

defineComponent(HealthBar)

proc pairProc*(quantity: LimitedQuantity): HealthPairProc =
  result = proc(): HealthPair =
    (max(quantity.cur.int, 0), quantity.max.int)

proc progressBar*(healthProc: HealthPairProc,
                  size = vec(),
                  foreground = rgb(0, 0, 0),
                  background = rgb(0, 0, 0),
                 ): Node =
  let
    border = 10.0
  SpriteNode(
    size: size + vec(border),
    color: rgb(32, 32, 32),
    children: newSeqOf[Node](
      BindNode[HealthPair](
        item: healthProc,
        node: (proc(pair: HealthPair): Node =
          let pct = pair.cur / pair.max
          Node(children: @[
            SpriteNode(
              size: size,
              color: background,
            ),
            SpriteNode(
              pos: vec(size.x * lerp(pct, -0.5, 0.0), 0.0),
              size: vec(size.x * pct, size.y),
              color: foreground,
            ),
            BorderedTextNode(text: $pair.cur & " / " & $pair.max),
          ]),
        )
      )
    ),
  )

proc rawHealthBar*(health: Health, size = vec()): Node =
  progressBar(
    health.pairProc(),
    size=size,
    foreground=rgb(210, 32, 32),
    background=rgb(92, 64, 64)
  )
    
proc healthBarNode(health: Health, enemyStats: EnemyStats): Node =
  Node(
    children: @[
      rawHealthBar(health, size=vec(160, 20)),
      BorderedTextNode(
        text: "L" & $enemyStats.level,
        pos: vec(-60, -30),
      ),
      BorderedTextNode(
        text: enemyStats.name,
        pos: vec(40, -30),
      ),
    ]
  )

defineDrawSystem:
  priority = -100
  components = [HealthBar, Transform]
  proc drawHealthBarNodes*(resources: ResourceManager, camera: Camera) =
    healthBar.menu.pos = transform.pos + camera.offset + vec(0, -75)
    renderer.draw(healthBar.menu, resources)

defineSystem:
  components = [HealthBar, Health, EnemyStats]
  proc updateHealthBarNodes*(menus: var MenuManager, input: InputManager) =
    if healthBar.menu == nil:
      healthBar.menu = healthBarNode(health, enemyStats)
    healthBar.menu.update(menus, input)
