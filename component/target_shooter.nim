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
    num, count, count, createSpread,
    Rune.update,
      num, grow,
    done,
    ]

  spell1 = spell1Desc.parse()
  spell2 = spell2Desc.parse()
  spell3 = spell3Desc.parse()

var
  varSpellDesc = @[createSingle]
  varSpell = varSpellDesc.parse()

  inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]
  runes = [num, count, mult, createSingle, createSpread, createBurst, despawn, Rune.update, done, wave, turn, grow]

proc drawSpell(renderer: RendererPtr, spell: SpellDesc, pos: Vec, resources: var ResourceManager) =
  let size = vec(48)
  for i in 0..<spell.len:
    let
      rune = spell[i]
      sprite = resources.loadSprite(rune.textureName(), renderer)
      curPos = pos + vec(i.float * (size.x - 6.0), 0.0)
      r = rect.rect(curPos, size)
    renderer.draw(sprite, r)

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

defineSystem:
  proc targetedShoot*(input: InputManager) =
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
          varSpellDesc.add runes[i]
          varSpell = varSpellDesc.parse()
      if input.isPressed(backspace) and varSpellDesc.len > 0:
        varSpellDesc.del(varSpellDesc.len - 1)
        varSpell = varSpellDesc.parse()
      if input.isPressed(Input.delete):
        varSpellDesc = @[]
        varSpell = varSpellDesc.parse()

      if input.isPressed(Input.spell1):
        result &= spell1.handleSpellCast(t.pos, dir)
      if input.isPressed(Input.spell2):
        result &= spell2.handleSpellCast(t.pos, dir)
      if input.isPressed(Input.spell3):
        result &= spell3.handleSpellCast(t.pos, dir)
      if input.isPressed(Input.jump):
        result &= varSpell.handleSpellCast(t.pos, dir)
