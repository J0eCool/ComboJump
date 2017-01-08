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
  player_stats,
  resources,
  stages,
  system,
  vec,
  util

type HudMenu* = ref object of Component
  menu: Node

proc hudMenuNode(health: Health, mana: Mana, stats: ptr PlayerStats, stageData: ptr StageData): Node =
  Node(
    children: @[
      Node(
        pos: vec(220, 60),
        children: newSeqOf[Node](
          rawHealthBar(health, size=vec(400, 35))
        ),
      ),
      Node(
        pos: vec(220, 105),
        children: newSeqOf[Node](
          progressBar(
            mana.pairProc(),
            size=vec(400, 25),
            foreground=color(32, 32, 210, 255),
            background=color(64, 64, 92, 255),
          )
        ),
      ),
      BindNode[int](
        item: (proc(): int = stats.level),
        node: (proc(level: int): Node =
          Node(
            children: @[
              BorderedTextNode(
                pos: vec(50, 18),
                text: "Level " & $stats.level,
                color: color(255, 255, 255, 255),
              ),
              Node(
                pos: vec(270, 18),
                children: @[
                  progressBar(
                    (proc(): HealthPair = (stats.xp, stats[].xpToNextLevel())),
                    size=vec(300, 16),
                    foreground=color(255, 255, 255, 255),
                    background=color(64, 64, 64, 255),
                  ),
                ],
              ),
            ],
          )
        ),
      ),
      BindNode[int](
        item: (proc(): int = stageData.currentStage),
        node: (proc(stageIdx: int): Node =
          BorderedTextNode(
            pos: vec(1100, 50),
            text: "Stage: " & levels[stageData.currentStage].name,
            color: color(255, 255, 255, 255),
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
  proc updateHudMenu*(input: InputManager, stats: var PlayerStats, stageData: var StageData) =
    entities.forComponents entity, [
      HudMenu, hudMenu,
    ]:
      if hudMenu.menu == nil:
        entities.forComponents entity, [
          Health, health,
          Mana, mana,
        ]:
          hudMenu.menu = hudMenuNode(health, mana, addr stats, addr stageData)
          break
        if hudMenu.menu == nil:
          return
      hudMenu.menu.update(input)
