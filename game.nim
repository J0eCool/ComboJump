import math, macros, sdl2

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  system/render,
  system/update_progress_bar,
  camera,
  entity,
  event,
  game_system,
  input,
  program,
  resources,
  vec,
  util

type Game* = ref object of Program
  resources*: ResourceManager
  entities*: Entities
  camera*: Camera
  dt*: float

method loadEntities*(game: Game) {.base.}

proc newGame*(screenSize: Vec): Game =
  new result
  result.title = "Game"
  result.camera.screenSize = screenSize

method init*(game: Game) =
  game.initProgram()
  game.resources = newResourceManager()
  game.loadEntities()

method loadEntities*(game: Game) =
  discard

method onRemove*(game: Game, entity: Entity) =
  discard

proc process*(game: Game, events: Events) =
  for event in events:
    case event.kind
    of addEntity:
      game.entities.add event.entity
    of removeEntity:
      game.onRemove(event.entity)
      game.entities.remove event.entity
    of loadStage:
      game.entities = event.stage

proc drawGame*(renderer: RendererPtr, game: Game) =
  game.entities.updateProgressBars()

  game.entities.loadResources(game.resources, renderer)

method draw*(renderer: RendererPtr, game: Game) =
  renderer.drawGame(game)

method update*(game: Game, dt: float) =
  game.dt = dt

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newGame(screenSize), screenSize)
