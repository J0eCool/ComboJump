import sdl2

import
  component/health,
  component/limited_quantity,
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

type HealthBar* = ref object of Component
  isPlayer*: bool
  menu: Node

proc rawHealthBar(health: Health, size = vec()): Node =
  let
    border = 10.0
  SpriteNode(
    size: size + vec(border),
    color: color(32, 32, 32, 255),
    children: newSeqOf[Node](
      BindNode[int](
        item: (proc(): int = health.cur.int),
        node: (proc(cur: int): Node =
          Node(children: @[
            SpriteNode(
              size: size,
              color: color(92, 64, 64, 255),
            ),
            SpriteNode(
              pos: vec(size.x * lerp(health.pct, -0.5, 0.0), 0.0),
              size: vec(size.x * health.pct, size.y),
              color: color(210, 32, 32, 255),
            ),
            BorderedTextNode(
              text: $cur & " / " & $health.max.int,
              color:
                if health.pct < 0.3:
                  color(255, 0, 0, 255)
                else:
                  color(255, 255, 255, 255),
            ),
          ]),
        )
      )
    ),
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

proc playerHealthBarNode(health: Health): Node =
  Node(
    pos: vec(220, 30),
    children: newSeqOf[Node](
      rawHealthBar(health, size=vec(400, 35))
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawHealthBarNodes*(resources: var ResourceManager, camera: Camera) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Transform, transform,
    ]:
      if not healthBar.isPlayer:
        healthBar.menu.pos = transform.pos + camera.offset + vec(0, -75)
      renderer.draw(healthBar.menu, resources)

defineSystem:
  proc updateHealthBarNodes*(input: InputManager) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Health, health,
      Transform, transform,
    ]:
      if healthBar.menu == nil:
        healthBar.menu =
          if healthBar.isPlayer:
            playerHealthBarNode(health)
          else:
            healthBarNode(health)
      healthBar.menu.update(input)
