import math, macros, sdl2, times

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/collider,
  system/render,
  camera,
  color,
  drawing,
  entity,
  event,
  game,
  game_system,
  input,
  logging,
  notifications,
  player_stats,
  prefabs,
  program,
  quests,
  resources,
  save,
  scrolling_background,
  single_sym_dylib,
  spell_creator,
  stages,
  vec,
  unit_tests,
  util

type NanoGame* = ref object of Game
  player: Entity
  background: ScrollingBackground
  stageData: StageData
  spellData: SpellData
  stats: PlayerStats
  notifications: N10nManager
  questData: QuestData

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"
  result.background = newScrollingBackground()
  result.stageData = newStageData()
  result.spellData = newSpellData()
  result.stats = newPlayerStats()
  result.notifications = newN10nManager()
  result.questData = newQuestData()
  load(result.spellData, result.stageData, result.stats)

proc newTestNanoGame*(): NanoGame =
  new result
  result.background = newScrollingBackground()
  result.spellData = newSpellData()
  result.stats = newPlayerStats()
  result.notifications = newN10nManager()
  result.questData = newQuestData()

  result.stageData = newTestStageData()

method loadEntities*(game: NanoGame) =
  game.entities = @[]

method onRemove*(game: NanoGame, entity: Entity) =
  game.notifications.add N10n(kind: entityRemoved, entity: entity)

importAllSystems()
defineDylibs()
defineSystemCalls(NanoGame)

method draw*(renderer: RendererPtr, game: NanoGame) =
  game.background.loadBackgroundAssets(game.resources, renderer)

  renderer.drawSystems(game)
  renderer.drawGame(game)

  let font = game.resources.loadFont("nevis.ttf")
  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          font, rgb(0, 0, 0))

method update*(game: NanoGame, dt: float) =
  log "NanoGame", debug, "Update - Begin"
  game.dt = dt

  game.player = nil
  for e in game.entities:
    let c = e.getComponent(Collider)
    if c != nil and c.layer == Layer.player:
      game.player = e

  game.updateSystems()
  log "NanoGame", debug, "Update - End"


when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
