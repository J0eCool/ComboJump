import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/[
    camera_target,
    cave_player_shooter,
    collider,
    damage_component,
    enemy_movement,
    health,
    limited_time,
    movement,
    platformer_control,
    popup_text,
    remove_when_offscreen,
    room_viewer,
    sprite,
    transform,
  ],
  mapgen/[
    tile_room,
  ],
  menu/[
    title_menu,
  ],
  system/[
    bullet_update,
    collisions,
    physics,
  ],
  color,
  entity,
  entity_json,
  event,
  game,
  game_system,
  input,
  jsonparse,
  menu,
  notifications,
  program,
  screen_shake,
  vec

# Imported last because of system rebuild determinism
import menu/entity_render_node

type CaveLunkGame* = ref object of Game
  player: Entity
  shake: ScreenShake
  notifications: N10nManager

defineSystemCalls(CaveLunkGame)

type
  CaveLunkController = ref object of Controller

proc caveLunkView(game: CaveLunkGame, controller: CaveLunkController): Node {.procvar.} =
  EntityRenderNode(
    entities: game.entities,
    camera: game.camera,
    update: (proc() =
      if game.input.isPressed(Input.escape):
        controller.shouldPop = true
      game.updateSystems()
    ),
  )

proc newCaveLunkMenu(game: CaveLunkGame): MenuBase =
  downcast(Menu[CaveLunkGame, CaveLunkController](
    model: game,
    view: caveLunkView,
    controller: CaveLunkController(),
  ))

proc newCaveLunkGame*(screenSize: Vec): CaveLunkGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "Cavelunk"
  result.notifications = newN10nManager()

proc newPlayer(): Entity =
  result = loadPrefab("CavePlayer")
  result.getComponent(Transform).pos = vec(500, 500)

proc roomEntities(room: RoomGrid, screenSize, pos: Vec): Entities =
  @[room.buildRoomEntity(pos, vec(64))]

proc newEnemy(pos: Vec, stayOn: bool): Entity =
  newEntity("Enemy", [
    Transform(
      pos: pos,
      size: vec(48, 64),
    ),
    newHealth(5),
    Movement(usesGravity: true),
    Collider(layer: Layer.enemy),
    EnemyMovePacing(
      moveSpeed: 200,
      facingSign: -1.0,
      stayOnPlatforms: stayOn,
    ),
    Sprite(
      textureName: "Goblin.png",
      flipAssetX: true,
    ),
  ])

method loadEntities*(game: CaveLunkGame) =
  game.player = newPlayer()
  game.entities = @[
    game.player,
    newEnemy(vec(256, 216), false),
    newEnemy(vec(768, 216), true),
    newEnemy(vec(1100, 616), true),
  ] & roomEntities(
    fromJson[RoomGrid](readJsonFile("assets/rooms/testbox.room")),
    game.camera.screenSize,
    vec(0, 0))
  game.menus.push newTitleMenu("CaveLunk", proc(): MenuBase =
    newCaveLunkMenu(game)
  )

  # Work through any first-frame jank during transition. Kinda hacky.
  game.updateSystems()

method draw*(renderer: RendererPtr, game: CaveLunkGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: CaveLunkGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newCaveLunkGame(screenSize), screenSize)
