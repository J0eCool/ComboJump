import sdl2

import
  component/health,
  component/limited_quantity,
  component/mana,
  component/transform,
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
  HealthPair = tuple[cur: int, max: int]

proc progressBar*(quantity: LimitedQuantity,
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
        item: (proc(): HealthPair = (max(quantity.cur.int, 0), quantity.max.int)),
        node: (proc(pair: HealthPair): Node =
          Node(children: @[
            SpriteNode(
              size: size,
              color: background,
            ),
            SpriteNode(
              pos: vec(size.x * lerp(quantity.pct, -0.5, 0.0), 0.0),
              size: vec(size.x * quantity.pct, size.y),
              color: foreground,
            ),
            BorderedTextNode(
              text: $pair.cur & " / " & $pair.max,
              color:
                if quantity.pct < 0.3:
                  color(255, 0, 0, 255)
                else:
                  color(255, 255, 255, 255),
            ),
          ]),
        )
      )
    ),
  )

proc rawHealthBar*(health: Health, size = vec()): Node =
  progressBar(
    health,
    size=size,
    foreground=color(210, 32, 32, 255),
    background=color(92, 64, 64, 255)
  )
    
proc healthBarNode(health: Health): Node =
  BindNode[bool](
    item: (proc(): bool = health.pct < 1.0),
    node: (proc(visible: bool): Node =
      if not visible:
        Node()
      else:
        rawHealthBar(health, size=vec(160, 20))
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawHealthBarNodes*(resources: var ResourceManager, camera: Camera) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Transform, transform,
    ]:
      healthBar.menu.pos = transform.pos + camera.offset + vec(0, -75)
      renderer.draw(healthBar.menu, resources)

defineSystem:
  proc updateHealthBarNodes*(input: InputManager) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Health, health,
    ]:
      if healthBar.menu == nil:
        healthBar.menu = healthBarNode(health)
      healthBar.menu.update(input)
