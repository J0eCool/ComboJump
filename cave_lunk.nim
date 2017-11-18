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
  system/[
    bullet_update,
    collisions,
    physics,
  ],
  color,
  entity,
  event,
  game,
  game_system,
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
  newEntity("Player", [
    Transform(
      pos: vec(500, 500),
      size: vec(76, 68),
    ),
    Movement(usesGravity: true),
    Collider(layer: Layer.player),
    PlatformerControl(
      moveSpeed: 400,
      jumpHeight: 240,
    ),
    CavePlayerShooter(
      fireRate: 3.0,
    ),
    Sprite(
      textureName: "Wizard2.png",
    ),
    CameraTarget(verticallyLocked: true),
  ])

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
      color: red,
    ),
  ])

method loadEntities*(game: CaveLunkGame) =
  game.player = newPlayer()
  game.entities = @[
    game.player,
    newEnemy(vec(256, 216), false),
    newEnemy(vec(768, 216), true),
    newEnemy(vec(1208, 716), true),
  ] & roomEntities(
    fromJson[RoomGrid](readJsonFile("assets/rooms/testbox.room")),
    game.camera.screenSize,
    vec(0, 0))
  game.menus.push newCaveLunkMenu(game)

method draw*(renderer: RendererPtr, game: CaveLunkGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: CaveLunkGame, dt: float) =
  game.dt = dt

  game.updateSystems()

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newCaveLunkGame(screenSize), screenSize)
