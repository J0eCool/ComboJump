import
  math,
  sdl2

import
  component/bullet,
  component/collider,
  component/damage,
  component/mana,
  component/movement,
  component/player_control,
  component/transform,
  component/sprite,
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


let
  spell1Desc = @[createSingle]
  spell2Desc = @[
    num, count, count, count, count, createSpread,
      Rune.update,
        num, count, wave, mult, turn,
      done,
      num, count, count, createBurst,
        Rune.update,
          num, grow,
        done,
        createSingle,
        despawn,
      despawn,
    ]
  spell3Desc = @[
    num, count, createSpread,
    createSingle,
      Rune.update,
        num, grow,
      done,
      num, count, createBurst,
      despawn,
    despawn,
    ]

  spell1 = spell1Desc.parse()
  spell2 = spell2Desc.parse()
  spell3 = spell3Desc.parse()

  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, Rune.update, done, wave, turn, grow, moveUp, moveSide, nearest, startPos]

var
  varSpellDesc = @[createSingle]
  varSpell = varSpellDesc.parse()
  varSpellIdx = 1

let spellFile = "out/custom_spell.json"
proc loadSpell() =
  let json = readJSONFile(spellFile)
  if json.kind == jsError:
    return
  fromJSON(varSpellDesc, json)
  varSpellIdx = varSpellDesc.len
  varSpell = varSpellDesc.parse()
proc saveSpell() =
  writeJSONFile(spellFile, varSpellDesc.toJSON)

proc addRune(rune: Rune) =
  varSpellDesc.insert(rune, varSpellIdx)
  varSpellIdx += 1
  varSpell = varSpellDesc.parse()
  saveSpell()

proc deleteRune() =
  varSpellDesc.delete(varSpellIdx - 1)
  varSpellIdx -= 1
  varSpell = varSpellDesc.parse()
  saveSpell()

proc clearVarSpell() =
  varSpellDesc = @[]
  varSpell = varSpellDesc.parse()
  saveSpell()
  varSpellIdx = 0

loadSpell()

proc drawSpell(renderer: RendererPtr, spell: SpellDesc, pos: Vec, resources: var ResourceManager) =
  let size = vec(48)
  for i in 0..<spell.len:
    let
      rune = spell[i]
      sprite = resources.loadSprite(rune.textureName(), renderer)
      curPos = pos + vec(i.float * (size.x - 6.0), 0.0)
      r = rect.rect(curPos, size)
    renderer.draw(sprite, r)

let testMenu = SpriteNode(
    pos: vec(950, 300),
    size: vec(300, 400),
    children: @[
      Button(
        pos: vec(0, -160),
        size: vec(280, 50),
        onClick: proc() = deleteRune()
      ),
      List(
        spacing: vec(10),
        width: 5,
        size: vec(300, 200),
        numItems: (proc(): int = runes.len),
        listNodes: (proc(i: int): Node =
          Button(
            size: vec(50, 50),
            onClick: (proc() =
              addRune(runes[i])
            ),
            children: @[
              SpriteNode(
                size: vec(48, 48),
                textureName: runes[i].textureName,
              ).Node,
            ],
          ),
        ),
      ),
    ],
  )

defineDrawSystem:
  proc drawSpells*(resources: var ResourceManager) =
    renderer.drawSpell(spell1Desc, vec(60, 40), resources)
    renderer.drawSpell(spell2Desc, vec(60, 100), resources)
    renderer.drawSpell(spell3Desc, vec(60, 160), resources)

    renderer.drawSpell(varSpellDesc, vec(60, 860), resources)

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
    renderer.fillRect(rect.rect(vec(60 + 42 * varSpellIdx - 21, 860), vec(6, 40)),
                      color(0, 0, 0, 255))

    renderer.draw(testMenu, resources)

defineSystem:
  proc targetedShoot*(input: InputManager) =
    testMenu.update(input)
    result = @[]
    entities.forComponents e, [
      TargetShooter, sh,
      Targeting, targeting,
      Transform, t,
    ]:
      var dir = vec(0, -1)
      targeting.target.bindAs targetEntity:
        targetEntity.withComponent Transform, target:
          dir = (target.pos - t.pos).unit

      for i in 0..<min(inputs.len, runes.len):
        if input.isPressed(inputs[i]):
          addRune(runes[i])
      if input.isPressed(backspace) and varSpellDesc.len > 0 and varSpellIdx > 0:
        deleteRune()
      if input.isPressed(Input.delete):
        clearVarSpell()
      if input.isPressed(runeLeft):
        varSpellIdx = max(0, varSpellIdx - 1)
      if input.isPressed(runeRight):
        varSpellIdx = min(varSpellDesc.len, varSpellIdx + 1)

      let target = targeting.target.get()
      if input.isPressed(Input.spell1):
        result &= spell1.handleSpellCast(t.pos, dir, target)
      if input.isPressed(Input.spell2):
        result &= spell2.handleSpellCast(t.pos, dir, target)
      if input.isPressed(Input.spell3):
        result &= spell3.handleSpellCast(t.pos, dir, target)
      if input.isPressed(Input.jump):
        result &= varSpell.handleSpellCast(t.pos, dir, target)
