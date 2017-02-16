import sdl2

import
  component/[
    health,
    health_bar,
    limited_quantity,
    locked_door,
    mana,
    transform,
  ],
  camera,
  entity,
  event,
  game_system,
  input,
  menu,
  player_stats,
  resources,
  stages,
  vec,
  util

type HudMenu* = ref object of Component
  menu: Node

defineComponent(HudMenu)

proc hudMenuNode(player: Entity, stats: ptr PlayerStats, stageData: ptr StageData): Node =
  let
    health = player.getComponent(Health)
    mana = player.getComponent(Mana)
    keyCollection = player.getComponent(KeyCollection)
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
            text: "Stage: " & stageData[].currentStageName,
          )
        ),
      ),
      BindNode[int](
        item: (proc(): int = keyCollection.numKeys),
        node: (proc(keys: int): Node =
          Node(
            pos: vec(60, 850),
            children: @[
              SpriteNode(
                pos: vec(-15, 0),
                size: vec(42, 21),
                textureName: "Key.png",
              ),
              BorderedTextNode(
                pos: vec(25, 0),
                text: "x" & $keys,
              ),
            ],
          )
        ),
      ),
    ],
  )


defineDrawSystem:
  priority = -100
  components = [HudMenu]
  proc drawHudMenu*(resources: var ResourceManager, camera: Camera) =
    if hudMenu.menu != nil:
      renderer.draw(hudMenu.menu, resources)

defineSystem:
  components = [HudMenu]
  proc updateHudMenu*(input: InputManager, stats: var PlayerStats, stageData: var StageData, player: Entity) =
    if hudMenu.menu == nil and player != nil:
        hudMenu.menu = hudMenuNode(player, addr stats, addr stageData)
    if hudMenu.menu != nil:
      hudMenu.menu.update(input)
