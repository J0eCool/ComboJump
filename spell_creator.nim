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

var
  spellDescs = [
    @[createSingle],
    @[num, count, createSpread],
    @[createSingle, num, count, count, createBurst, despawn],
    @[num, count, count, createBurst, Rune.update, nearest, turn, done],
  ]

  spells: array[4, SpellParse]

  varSpell = 0
  varSpellIdx = 1

let
  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, Rune.update, done, wave, turn, grow, moveUp, moveSide, nearest, startPos]

proc inputString(rune: Rune): string =
  for i in 0..<runes.len:
    if rune == runes[i]:
      return $inputs[i]
  assert false, "Rune not found in runes array"

proc reparseAllSpells() =
  for i in 0..<spellDescs.len:
    spells[i] = spellDescs[i].parse()

let spellFile = "out/custom_spell.json"
proc loadSpell() =
  defer: reparseAllSpells()
  let json = readJSONFile(spellFile)
  if json.kind == jsError:
    return
  fromJSON(spellDescs, json)
  varSpellIdx = spellDescs[varSpell].len

proc saveSpell() =
  writeJSONFile(spellFile, spellDescs.toJSON)

proc addRune(rune: Rune) =
  spellDescs[varSpell].insert(rune, varSpellIdx)
  varSpellIdx += 1
  spells[varSpell] = spellDescs[varSpell].parse()
  saveSpell()

proc deleteRune() =
  spellDescs[varSpell].delete(varSpellIdx - 1)
  varSpellIdx -= 1
  spells[varSpell] = spellDescs[varSpell].parse()
  saveSpell()

proc clearVarSpell() =
  spellDescs[varSpell] = @[]
  spells[varSpell] = spellDescs[varSpell].parse()
  saveSpell()
  varSpellIdx = 0

proc clampSpellIndex() =
  varSpellIdx = clamp(varSpellIdx, 0, spellDescs[varSpell].len)

proc moveCursor(dir: int) =
  varSpellIdx += dir
  clampSpellIndex()

proc moveSpell(dir: int) =
  varSpell += dir
  varSpell = clamp(varSpell, 0, spellDescs.len)
  clampSpellIndex()

let
  runeMenu = SpriteNode(
    pos: vec(1020, 220),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(0, -160),
        size: vec(280, 50),
        onClick: (proc() = deleteRune()),
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
              addRune(rune)
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
        addRune(runes[i])
    if input.isPressed(backspace) and spellDescs[0].len > 0 and varSpellIdx > 0:
      deleteRune()
    if input.isPressed(Input.delete):
      clearVarSpell()
    if input.isPressed(runeLeft):
      moveCursor(-1)
    if input.isPressed(runeRight):
      moveCursor(+1)
    if input.isPressed(runeUp):
      moveSpell(-1)
    if input.isPressed(runeDown):
      moveSpell(+1)

loadSpell()

proc getSpells*(): array[0..3, SpellParse] =
  spells
proc getVarSpell*(): int =
  varSpell
proc getVarSpellIdx*(): int =
  varSpellIdx
proc getSpellDesc*(idx: int): SpellDesc =
  spellDescs[idx]
