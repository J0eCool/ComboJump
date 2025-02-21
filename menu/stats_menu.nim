import
  sdl2

import
  input,
  entity,
  event,
  game_system,
  menu,
  player_stats,
  resources,
  vec,
  util

type
  StatsMenu* = ref object of Component
    menu: Node

defineComponent(StatsMenu)

proc statsMenuNode(stats: ptr PlayerStats): Node =
  BindNode[PlayerStats](
    item: (proc(): PlayerStats = stats[]),
    node: (proc(stats: PlayerStats): Node =
      stringListNode(@[
          "Level: " & $stats.level,
          "XP: " & $stats.xp & "/" & $stats.xpToNextLevel,
          "Health: " & $stats.maxHealth,
          "Mana: " & $stats.maxMana,
          "Mana Regen: " & $stats.manaRegen & "/s",
          "Damage: +" & formatFloat(100 * (stats.damage - 1)) & "%",
          "Cast Speed: +" & formatFloat(100 * (stats.castSpeed - 1)) & "%",
        ],
        pos=vec(200, 300),
      )
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawStatsMenu*(resources: ResourceManager) =
    entities.forComponents entity, [
      StatsMenu, statsMenu,
    ]:
      renderer.draw(statsMenu.menu, resources)

defineSystem:
  proc updateStatsMenu*(menus: var MenuManager, input: InputManager, stats: var PlayerStats) =
    entities.forComponents entity, [
      StatsMenu, statsMenu,
    ]:
      if statsMenu.menu == nil:
        statsMenu.menu = statsMenuNode(addr stats)
      statsMenu.menu.update(menus, input)
