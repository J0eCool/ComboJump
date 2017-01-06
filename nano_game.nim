import math, macros, sdl2, times

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  component/xp_on_death,
  system/render,
  camera,
  entity,
  event,
  input,
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
  background: ScrollingBackground
  stageData: StageData
  spellData: SpellData
  stats: PlayerStats

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"
  result.background = newScrollingBackground()
  result.stageData = newStageData()
  result.spellData = newSpellData()
  result.stats = newPlayerStats()
  load(result.spellData, result.stageData, result.stats)

method loadEntities*(game: NanoGame) =
  game.entities = @[]

method onRemove*(game: NanoGame, entity: Entity) =
  onRemoveXpOnDeath(entity, game.stats)

importAllSystems()
defineSystemCalls(NanoGame)

var testlib = newSingleSymDylib[proc(): int {.nimcall.}]("testlib.dll", "getSomeNum")

method draw*(renderer: RendererPtr, game: NanoGame) =
  game.background.loadBackgroundAssets(game.resources, renderer)

  renderer.drawSystems(game)
  renderer.drawGame(game)

  let font = game.resources.loadFont("nevis.ttf")
  renderer.drawCachedText($testlib.getSym()(), vec(600, 600), font, color(0, 0, 0, 255))

  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          font, color(0, 0, 0, 255))

method update*(game: NanoGame, dt: float) =
  testlib.tryLoadLib()

  game.dt = dt

  game.updateSystems()

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
