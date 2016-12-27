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
  menu: Node

proc healthBarNode(health: Health): Node =
  let
    width = 200.0
    height = 25.0
    border = 10.0
  Node(
    children: newSeqOf[Node](
      SpriteNode(
        pos: vec(0, -75),
        size: vec(width + border, height + border),
        color: color(32, 32, 32, 255),
        children: newSeqOf[Node](
          BindNode[int](
            item: (proc(): int = health.cur.int),
            node: (proc(cur: int): Node =
              Node(children: @[
                SpriteNode(
                  size: vec(width, height),
                  color: color(92, 64, 64, 255),
                ),
                SpriteNode(
                  pos: vec(width * lerp(health.pct, -0.5, 0.0), 0.0),
                  size: vec(width * health.pct, height),
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
