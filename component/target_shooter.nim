import
  math,
  sdl2,
  sequtils

import
  component/bullet,
  component/collider,
  component/damage,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
  camera,
  drawing,
  entity,
  event,
  input,
  jsonparse,
  menu,
  newgun,
  option,
  rect,
  system/render,
  resources,
  system,
  targeting,
  vec,
  util

type
  TargetShooter* = ref object of Component

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
  fireInputs = [jump, spell1, spell2, spell3]
  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, Rune.update, done, wave, turn, grow, moveUp, moveSide, nearest, startPos]

proc reparseAllSpells() =
  for i in 0..<spellDescs.len:
    spells[i] = spellDescs[i].parse()

let spellFile = "out/custom_spell.json"
proc loadSpell() =
  let json = readJSONFile(spellFile)
  if json.kind == jsError:
    return
  fromJSON(spellDescs, json)
  varSpellIdx = spellDescs[varSpell].len
  reparseAllSpells()

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

loadSpell()

let
  testMenu = SpriteNode(
    pos: vec(1020, 220),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(0, -160),
        size: vec(280, 50),
        onClick: proc() = deleteRune()
      ),
      List[Rune](
        spacing: vec(10),
        width: 5,
        size: vec(300, 200),
        items: (proc(): seq[Rune] = @runes),
        listNodes: (proc(rune: Rune): Node =
          Button(
            size: vec(50, 50),
            onClick: (proc() =
              addRune(rune)
            ),
            children: @[
              SpriteNode(
                size: vec(48, 48),
                textureName: rune.textureName,
              ).Node,
            ],
          )
        ),
      ),
    ]
  )
  varSpellMenu = List[int](
    pos: vec(20, 20),
    spacing: vec(4),
    items: (proc(): seq[int] = toSeq(0..<spells.len)),
    listNodes: (proc(descIdx: int): Node =
      SpriteNode(
        size: vec(810, 48),
        color: color(128, 128, 128, 255),
        children: @[
          BindNode[int](
            pos: vec(-400, -12),
            item: (proc(): int =
              if descIdx != varSpell:
                -1
              else:
                varSpellIdx
            ),
            node: (proc(idx: int): Node =
              if idx == -1:
                Node()
              else:
                SpriteNode(
                  pos: vec(20 * idx, 12),
                  size: vec(4, 30),
                  color: color(0, 0, 0, 255),
                )
            ),
          ),
          List[Rune](
            spacing: vec(-4, 0),
            horizontal: true,
            pos: vec(0, 0),
            size: vec(800, 24),
            items: (proc(): seq[Rune] = spellDescs[descIdx]),
            listNodes: (proc(rune: Rune): Node =
              SpriteNode(
                size: vec(24, 24),
                textureName: rune.textureName,
              )
            ),
          ),
        ],
      )
    ),
  )

defineDrawSystem:
  proc drawSpells*(resources: var ResourceManager) =
    for i in 0..<min(inputs.len, runes.len):
      let
        rows = 4
        x = (i div rows) * 120
        y = (i mod rows) * 50
        pos = vec(60 + x, 660 + y)
        sprite = resources.loadSprite(runes[i].textureName(), renderer)
        r = rect.rect(pos + vec(50, 0), vec(48))
      renderer.draw(sprite, r)
      renderer.drawCachedText($inputs[i] & " -", pos,
                              resources.loadFont("nevis.ttf"),
                              color(0, 0, 0, 255))

    renderer.draw(varSpellMenu, resources)
    renderer.draw(testMenu, resources)

defineSystem:
  proc targetedShoot*(input: InputManager, camera: Camera) =
    testMenu.update(input)
    varSpellMenu.update(input)

    result = @[]
    entities.forComponents e, [
      TargetShooter, sh,
      Targeting, targeting,
      Transform, t,
    ]:
      var dir = vec(0, -1)
      targeting.target.tryPos.bindAs targetPos:
        dir = (targetPos - t.pos).unit

      for i in 0..<min(inputs.len, runes.len):
        if input.isPressed(inputs[i]):
          addRune(runes[i])
      if input.isPressed(backspace) and spellDescs[0].len > 0 and varSpellIdx > 0:
        deleteRune()
      if input.isPressed(Input.delete):
        clearVarSpell()
      if input.isPressed(runeLeft):
        varSpellIdx = max(0, varSpellIdx - 1)
      if input.isPressed(runeRight):
        varSpellIdx = min(spellDescs[varSpell].len, varSpellIdx + 1)
      if input.isPressed(runeUp):
        varSpell = max(0, varSpell - 1)
        varSpellIdx = clamp(varSpellIdx, 0, spellDescs[varSpell].len)
      if input.isPressed(runeDown):
        varSpell = min(spellDescs.len, varSpell + 1)
        varSpellIdx = clamp(varSpellIdx, 0, spellDescs[varSpell].len)

      for i in 0..<spells.len:      
        if input.isPressed(fireInputs[i]):
          result &= spells[i].handleSpellCast(t.pos, dir, targeting.target)
