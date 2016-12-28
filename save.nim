import tables

import
  entity,
  event,
  jsonparse,
  spell_creator,
  stages,
  system

const saveFile = "out/save.json"

proc save(spellData: SpellData, stageData: StageData) =
  var json = JSON(kind: jsObject, obj: initTable[string, JSON]())
  json.obj["spellData"] = spellData.toJSON()
  json.obj["stageData"] = stageData.toJSON()
  writeJSONFile(saveFile, json, pretty=true)

proc load*(spellData: var SpellData, stageData: var StageData) =
  let json = readJSONFile(saveFile)
  if json.kind == jsError:
    return
  assert json.kind == jsObject
  spellData.fromJSON(json.obj["spellData"])
  stageData.fromJSON(json.obj["stageData"])

defineSystem:
  proc updateSaveSystem*(spellData: var SpellData, stageData: var StageData) =
    if spellData.shouldSave or stageData.shouldSave:
      spellData.shouldSave = false
      stageData.shouldSave = false
      save(spellData, stageData)
