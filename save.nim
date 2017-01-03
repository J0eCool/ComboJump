import tables

import
  entity,
  event,
  jsonparse,
  player_stats,
  spell_creator,
  stages,
  system

const saveFile = "out/save.json"

proc save(spellData: SpellData, stageData: StageData, stats: PlayerStats) =
  var json = JSON(kind: jsObject, obj: initTable[string, JSON]())
  json.obj["spellData"] = spellData.toJSON()
  json.obj["stageData"] = stageData.toJSON()
  json.obj["stats"] = stats.toJSON()
  writeJSONFile(saveFile, json, pretty=true)

proc load*(spellData: var SpellData, stageData: var StageData, stats: var PlayerStats) =
  let json = readJSONFile(saveFile)
  if json.kind == jsError:
    return
  assert json.kind == jsObject
  spellData.fromJSON(json.obj["spellData"])
  stageData.fromJSON(json.obj["stageData"])
  stats.fromJSON(json.obj["stats"])

defineSystem:
  proc updateSaveSystem*(spellData: var SpellData, stageData: var StageData, stats: var PlayerStats) =
    if spellData.shouldSave or stageData.shouldSave or stats.shouldSave:
      spellData.shouldSave = false
      stageData.shouldSave = false
      stats.shouldSave = false
      save(spellData, stageData, stats)
