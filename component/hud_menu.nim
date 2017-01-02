import sdl2

import
  component/health,
  component/health_bar,
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

type HudMenu* = ref object of Component
  menu: Node

proc hudMenuNode(health: Health, mana: Mana): Node =
  Node(
    children: @[
      Node(
        pos: vec(220, 30),
        children: newSeqOf[Node](
          rawHealthBar(health, size=vec(400, 35))
        ),
      ),
      Node(
        pos: vec(220, 75),
        children: newSeqOf[Node](
          progressBar(
            mana,
            size=vec(400, 25),
            foreground=color(32, 32, 210, 255),
            background=color(64, 64, 92, 255),
          )
        ),
      ),
    ],
  )


defineDrawSystem:
  priority = -100
  proc drawHudMenu*(resources: var ResourceManager, camera: Camera) =
    entities.forComponents entity, [
      HudMenu, hudMenu,
    ]:
      renderer.draw(hudMenu.menu, resources)

defineSystem:
  proc updateHudMenu*(input: InputManager) =
    entities.forComponents entity, [
      HudMenu, hudMenu,
    ]:
      if hudMenu.menu == nil:
        entities.forComponents entity, [
          Health, health,
          Mana, mana,
        ]:
          hudMenu.menu = hudMenuNode(health, mana)
          break
        if hudMenu.menu == nil:
          return
      hudMenu.menu.update(input)
