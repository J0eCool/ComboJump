import
  sdl2,
  sequtils

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
  SpellData = object
    spellDescs: array[4, SpellDesc]

    spells: array[4, SpellParse]

    varSpell: int
    varSpellIdx: int

proc newSpellData*(): SpellData =
  SpellData(
    spellDescs: [
      @[createSingle],
      @[],
      @[],
      @[],
    ],
    varSpellIdx: 1,
  )

var spellData = newSpellData()

let
  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, Rune.update, done, wave, turn, grow, moveUp, moveSide, nearest, startPos]

proc inputString(rune: Rune): string =
  for i in 0..<runes.len:
    if rune == runes[i]:
      return $inputs[i]
  assert false, "Rune not found in runes array"

proc reparseAllSpells(spellData: var SpellData) =
  for i in 0..<spellData.spellDescs.len:
    spellData.spells[i] = spellData.spellDescs[i].parse()

let spellFile = "out/custom_spell.json"
proc loadSpell(spellData: var SpellData) =
  defer: spellData.reparseAllSpells()
  let json = readJSONFile(spellFile)
  if json.kind == jsError:
    return
  fromJSON(spellData.spellDescs, json)
  spellData.varSpellIdx = spellData.spellDescs[spellData.varSpell].len

proc saveSpell(spellData: SpellData) =
  writeJSONFile(spellFile, spellData.spellDescs.toJSON)

proc addRune(spellData: var SpellData, rune: Rune) =
  spellData.spellDescs[spellData.varSpell].insert(rune, spellData.varSpellIdx)
  spellData.varSpellIdx += 1
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.saveSpell()

proc deleteRune(spellData: var SpellData) =
  if spellData.spellDescs[spellData.varSpell].len <= 0 or spellData.varSpellIdx <= 0:
    return
  spellData.spellDescs[spellData.varSpell].delete(spellData.varSpellIdx - 1)
  spellData.varSpellIdx -= 1
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.saveSpell()

proc clearVarSpell(spellData: var SpellData) =
  spellData.spellDescs[spellData.varSpell] = @[]
  spellData.spells[spellData.varSpell] = spellData.spellDescs[spellData.varSpell].parse()
  spellData.saveSpell()
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

let
  runeMenu = SpriteNode(
    pos: vec(1020, 220),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(0, -160),
        size: vec(280, 50),
        onClick: (proc() = spellData.deleteRune()),
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
              spellData.addRune(rune)
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
            ],
          )
        ),
      ),
    ]
  )
defineDrawSystem:
  priority = -100
  proc drawSpellCreator*(resources: var ResourceManager) =
    renderer.draw(runeMenu, resources)

defineSystem:
  proc updateSpellCreator*(input: InputManager) =
    runeMenu.update(input)
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

spellData.loadSpell()

proc getSpells*(): array[0..3, SpellParse] =
  spellData.spells
proc getVarSpell*(): int =
  spellData.varSpell
proc getVarSpellIdx*(): int =
  spellData.varSpellIdx
proc getSpellDesc*(idx: int): SpellDesc =
  spellData.spellDescs[idx]
