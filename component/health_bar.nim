import sdl2

import
  component/health,
  component/progress_bar,
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
  menu: Node

proc healthBarNode(health: Health): Node =
  Node(
    children: newSeqOf[Node](
      SpriteNode(
        pos: vec(0, -75),
        size: vec(210, 35),
        color: color(128, 128, 128, 255),
        children: newSeqOf[Node](
          BindNode[int](
            item: (proc(): int = health.cur.int),
            node: (proc(cur: int): Node =
              TextNode(text: $cur & " / " & $health.max.int)
            ),
          )
        ),
      )
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawHealthBarNodes*(resources: var ResourceManager, camera: Camera) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Transform, transform,
    ]:
      healthBar.menu.pos = transform.pos + camera.offset
      renderer.draw(healthBar.menu, resources)

defineSystem:
  proc updateHealthBarNodes*(input: InputManager) =
    entities.forComponents entity, [
      HealthBar, healthBar,
      Health, health,
      Transform, transform,
    ]:
      if healthBar.menu == nil:
        healthBar.menu = healthBarNode(health)
      healthBar.menu.update(input)
