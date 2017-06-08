import
  sequtils,
  tables

import
  spells/[
    runes,
    spell_parser,
  ],
  entity,
  event,
  game_system,
  input,
  jsonparse,
  menu,
  resources,
  vec,
  util

type
  SpellData* = object
    spellDescs*: array[4, SpellDesc]

    spells*: array[4, SpellParse]

    varSpell*: int
    varSpellIdx*: int

    capacity*: Table[Rune, int]
    shouldSave*: bool

proc reparseAllSpells(spellData: var SpellData)
proc newSpellData*(): SpellData =
  result = SpellData(
    spellDescs: [
      @[createSingle],
      @[],
      @[],
      @[],
    ],
    varSpellIdx: 1,
    capacity: initTable[Rune, int](32),
  )
  for r in Rune:
    result.capacity[r] = 0
  result.capacity[createSingle] = 1
  result.reparseAllSpells()

proc allRunes_calc(): seq[Rune] =
  result = @[]
  for rune in Rune:
    result.add rune
const allRunes = allRunes_calc()

proc reparseAllSpells(spellData: var SpellData) =
  for i in 0..<spellData.spellDescs.len:
    spellData.spells[i] = spellData.spellDescs[i].parse()

proc fromJson*(spellData: var SpellData, json: Json) =
  assert json.kind == jsObject
  spellData.spellDescs.fromJson(json.obj["spellDescs"])
  spellData.capacity.fromJson(json.obj["capacity"])
  spellData.reparseAllSpells()
  spellData.varSpellIdx = spellData.spellDescs[spellData.varSpell].len
proc toJson*(spellData: SpellData): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  result.obj["spellDescs"] = spellData.spellDescs.toJson()
  result.obj["capacity"] = spellData.capacity.toJson()

proc runeCount(spellDesc: SpellDesc, rune: Rune): int =
  for r in spellDesc:
    if r == rune:
      result += 1

proc runeCount(spellData: SpellData, rune: Rune): int =
  for desc in spellData.spellDescs:
    result += desc.runeCount(rune)

proc getCapacity*(spellData: SpellData, rune: Rune): int =
  spellData.capacity[rune]

proc available*(spellData: SpellData, rune: Rune): int =
  spellData.capacity[rune] - spellData.runeCount(rune)

proc unlockedRunes*(spellData: SpellData): seq[Rune] =
  result = @[]
  for rune in allRunes:
    if spellData.capacity[rune] > 0:
      result.add rune

proc addRuneCapacity*(spellData: var SpellData, rune: Rune) =
  spellData.capacity[rune] += 1
  spellData.shouldSave = true

proc addRune*(spellData: var SpellData, rune: Rune) =
  if spellData.available(rune) <= 0:
    return
  spellData.spellDescs[spellData.varSpell].insert(rune, spellData.varSpellIdx)
  spellData.varSpellIdx += 1
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.shouldSave = true

proc deleteRune*(spellData: var SpellData) =
  if spellData.spellDescs[spellData.varSpell].len <= 0 or spellData.varSpellIdx <= 0:
    return
  spellData.spellDescs[spellData.varSpell].delete(spellData.varSpellIdx - 1)
  spellData.varSpellIdx -= 1
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.shouldSave = true

proc clearVarSpell(spellData: var SpellData) =
  spellData.spellDescs[spellData.varSpell] = @[]
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.shouldSave = true
  spellData.varSpellIdx = 0

proc clampSpellIndex(spellData: var SpellData) =
  spellData.varSpellIdx = clamp(spellData.varSpellIdx, 0, spellData.spellDescs[spellData.varSpell].len)

proc moveCursor(spellData: var SpellData, dir: int) =
  spellData.varSpellIdx += dir
  spellData.clampSpellIndex()

proc moveSpell(spellData: var SpellData, dir: int) =
  spellData.varSpell += dir
  spellData.varSpell = clamp(spellData.varSpell, 0, spellData.spellDescs.len-1)
  spellData.clampSpellIndex()

defineSystem:
  proc updateSpellCreator*(input: InputManager, spellData: var SpellData) =
    if input.isPressed(backspace):
      spellData.deleteRune()
    if input.isPressed(Input.delete):
      spellData.clearVarSpell()
    if input.isPressed(runeLeft):
      spellData.moveCursor(-1)
    if input.isPressed(runeRight):
      spellData.moveCursor(+1)
    if input.isPressed(runeUp):
      spellData.moveSpell(-1)
    if input.isPressed(runeDown):
      spellData.moveSpell(+1)
