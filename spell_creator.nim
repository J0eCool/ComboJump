import
  sdl2,
  sequtils,
  tables

import
  entity,
  event,
  input,
  jsonparse,
  menu,
  newgun,
  resources,
  system,
  vec,
  util

type
  SpellData* = object
    spellDescs*: array[4, SpellDesc]

    spells*: array[4, SpellParse]

    varSpell*: int
    varSpellIdx*: int

    capacity: Table[Rune, int]
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

let
  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, wave, turn, grow, moveUp, moveSide, nearest, startPos]

proc inputString(rune: Rune): string =
  for i in 0..<runes.len:
    if rune == runes[i]:
      return $inputs[i]
  assert false, "Rune not found in runes array"

proc reparseAllSpells(spellData: var SpellData) =
  for i in 0..<spellData.spellDescs.len:
    spellData.spells[i] = spellData.spellDescs[i].parse()

proc fromJSON*(spellData: var SpellData, json: JSON) =
  assert json.kind == jsObject
  spellData.spellDescs.fromJSON(json.obj["spellDescs"])
  spellData.capacity.fromJSON(json.obj["capacity"])
  spellData.reparseAllSpells()
proc toJSON*(spellData: SpellData): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["spellDescs"] = spellData.spellDescs.toJSON()
  result.obj["capacity"] = spellData.capacity.toJSON()

proc runeCount(spellDesc: SpellDesc, rune: Rune): int =
  for r in spellDesc:
    if r == rune:
      result += 1

proc runeCount(spellData: SpellData, rune: Rune): int =
  for desc in spellData.spellDescs:
    result += desc.runeCount(rune)

proc available(spellData: SpellData, rune: Rune): int =
  return spellData.capacity[rune] - spellData.runeCount(rune)

proc addRuneCapacity*(spellData: var SpellData, rune: Rune) =
  spellData.capacity[rune] += 1
  spellData.shouldSave = true

proc addRune(spellData: var SpellData, rune: Rune) =
  if spellData.available(rune) <= 0:
    return
  spellData.spellDescs[spellData.varSpell].insert(rune, spellData.varSpellIdx)
  spellData.varSpellIdx += 1
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.shouldSave = true

proc deleteRune(spellData: var SpellData) =
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
  spellData.varSpell = clamp(spellData.varSpell, 0, spellData.spellDescs.len)
  spellData.clampSpellIndex()

type
  RuneMenu* = ref object of Component
    menu: Node

proc runeMenuNode(spellData: ptr SpellData): Node =
  SpriteNode(
    pos: vec(1020, 220),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(0, -160),
        size: vec(280, 50),
        onClick: (proc() = spellData[].deleteRune()),
        children: @[
          TextNode(
            text: "Backspace",
          ).Node,
        ],
      ),
      List[Rune](
        spacing: vec(10),
        width: 4,
        size: vec(300, 200),
        items: (proc(): seq[Rune] = @runes),
        listNodes: (proc(rune: Rune): Node =
          Button(
            size: vec(65, 50),
            onClick: (proc() =
              spellData[].addRune(rune)
            ),
            children: @[
              SpriteNode(
                pos: vec(-10, 0),
                size: vec(48, 48),
                textureName: rune.textureName,
              ),
              TextNode(
                pos: vec(22, 12),
                text: rune.inputString[^1..^0],
                color: color(0, 0, 0, 255),
              ),
              BindNode[int](
                item: (proc(): int = spellData[].available(rune)),
                node: (proc(count: int): Node =
                  BorderedTextNode(
                    pos: vec(22, -12),
                    text: $count,
                    color:
                      if count > 0:
                        color(255, 240, 32, 255)
                      else:
                        color(128, 128, 128, 255),
                  )
                ),
              ),
            ],
          )
        ),
      ),
    ]
  )

defineDrawSystem:
  priority = -100
  proc drawRuneMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      RuneMenu, runeMenu,
    ]:
      renderer.draw(runeMenu.menu, resources)

defineSystem:
  proc updateRuneMenu*(input: InputManager, spellData: var SpellData) =
    entities.forComponents entity, [
      RuneMenu, runeMenu,
    ]:
      if runeMenu.menu == nil:
        runeMenu.menu = runeMenuNode(addr spellData)
      menu.update(runeMenu.menu, input)

defineSystem:
  proc updateSpellCreator*(input: InputManager, spellData: var SpellData) =
    for i in 0..<min(inputs.len, runes.len):
      if input.isPressed(inputs[i]):
        spellData.addRune(runes[i])
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
