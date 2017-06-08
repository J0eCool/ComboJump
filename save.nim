import tables

import
  entity,
  event,
  game_system,
  jsonparse,
  player_stats,
  spell_creator,
  stages

const saveFile = "out/save.json"

proc save(spellData: SpellData, stageData: StageData, stats: PlayerStats) =
  var json = Json(kind: jsObject, obj: initTable[string, Json]())
  json.obj["spellData"] = spellData.toJson()
  json.obj["stageData"] = stageData.toJson()
  json.obj["stats"] = stats.toJson()
  writeJsonFile(saveFile, json, pretty=true)

proc load*(spellData: var SpellData, stageData: var StageData, stats: var PlayerStats) =
  let json = readJsonFile(saveFile)
  if json.kind == jsError:
    return
  assert json.kind == jsObject
  spellData.fromJson(json.obj["spellData"])
  stageData.fromJson(json.obj["stageData"])
  stats.fromJson(json.obj["stats"])

defineSystem:
  proc updateSaveSystem*(spellData: var SpellData, stageData: var StageData, stats: var PlayerStats) =
    if spellData.shouldSave or stageData.shouldSave or stats.shouldSave:
      spellData.shouldSave = false
      stageData.shouldSave = false
      stats.shouldSave = false
      save(spellData, stageData, stats)
