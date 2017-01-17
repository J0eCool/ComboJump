import sdl2

import
  component/[
    enemy_stats,
    health,
    limited_quantity,
    mana,
    transform,
  ],
  camera,
  entity,
  event,
  input,
  menu,
  resources,
  system,
  vec,
  util

type
  HealthBar* = ref object of Component
    menu: Node
  HealthPair* = tuple[cur: int, max: int]
  HealthPairProc = proc(): HealthPair

proc pairProc*(quantity: LimitedQuantity): HealthPairProc =
  result = proc(): HealthPair =
    (max(quantity.cur.int, 0), quantity.max.int)

proc progressBar*(healthProc: HealthPairProc,
                  size = vec(),
                  foreground = color(0, 0, 0, 0),
                  background = color(0, 0, 0, 0),
                 ): Node =
  let
    border = 10.0
  SpriteNode(
    size: size + vec(border),
    color: color(32, 32, 32, 255),
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
            BorderedTextNode(
              text: $pair.cur & " / " & $pair.max,
              color: color(255, 255, 255, 255),
            ),
          ]),
        )
      )
    ),
  )

proc rawHealthBar*(health: Health, size = vec()): Node =
  progressBar(
    health.pairProc(),
    size=size,
    foreground=color(210, 32, 32, 255),
    background=color(92, 64, 64, 255)
  )
    
proc healthBarNode(health: Health, enemyStats: EnemyStats): Node =
  Node(
    children: @[
      rawHealthBar(health, size=vec(160, 20)),
      BorderedTextNode(
        text: "L" & $enemyStats.level,
        pos: vec(-60, -30),
        color: color(255, 255, 255, 255),
      ),
      BorderedTextNode(
        text: enemyStats.name,
        pos: vec(40, -30),
        color: color(255, 255, 255, 255),
      ),
    ]
  )

defineDrawSystem:
  priority = -100
  components = [HealthBar, Transform]
  proc drawHealthBarNodes*(resources: var ResourceManager, camera: Camera) =
    healthBar.menu.pos = transform.pos + camera.offset + vec(0, -75)
    renderer.draw(healthBar.menu, resources)

defineSystem:
  components = [HealthBar, Health, EnemyStats]
  proc updateHealthBarNodes*(input: InputManager) =
    if healthBar.menu == nil:
      healthBar.menu = healthBarNode(health, enemyStats)
    healthBar.menu.update(input)
