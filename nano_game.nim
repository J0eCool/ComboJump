import math, macros, sdl2, times

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  component/collider,
  component/xp_on_death,
  system/render,
  camera,
  drawing,
  entity,
  event,
  input,
  notifications,
  player_stats,
  prefabs,
  program,
  resources,
  save,
  scrolling_background,
  single_sym_dylib,
  spell_creator,
  stages,
  system,
  vec,
  util

type NanoGame* = ref object of Game
  player: Entity
  background: ScrollingBackground
  stageData: StageData
  spellData: SpellData
  stats: PlayerStats
  notifications: N10nManager

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"
  result.background = newScrollingBackground()
  result.stageData = newStageData()
  result.spellData = newSpellData()
  result.stats = newPlayerStats()
  result.notifications = newN10nManager()
  load(result.spellData, result.stageData, result.stats)

method loadEntities*(game: NanoGame) =
  game.entities = @[]

method onRemove*(game: NanoGame, entity: Entity) =
  discard

importAllSystems()
# defineDylibs()
defineSystemCalls(NanoGame)

import
  tests/[
    areas_test,
    notifications_test,
    transform_test,
  ]

method draw*(renderer: RendererPtr, game: NanoGame) =
  game.background.loadBackgroundAssets(game.resources, renderer)

  renderer.drawSystems(game)
  renderer.drawGame(game)

  let font = game.resources.loadFont("nevis.ttf")
  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          font, color(0, 0, 0, 255))

method update*(game: NanoGame, dt: float) =
  game.dt = dt

  game.player = nil
  for e in game.entities:
    let c = e.getComponent(Collider)
    if c != nil and c.layer == Layer.player:
      game.player = e

  game.updateSystems()

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
