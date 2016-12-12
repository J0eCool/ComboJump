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
  resources,
  system,
  targeting,
  vec,
  util

type
  TargetShooter* = ref object of Component


let
  spell1 = @[createSingle]
  spell2 = @[
    num, count, count, count, count, createSpread,
      Rune.update,
        num, count, wave, mult, turn,
      done,
      num, count, count, createBurst,
        Rune.update,
          num, count, count, grow,
        done,
        createSingle,
        despawn,
      despawn,
    ]

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
    renderer.drawSpell(spell1, vec(60, 80), resources)
    renderer.drawSpell(spell2, vec(60, 140), resources)

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

      if input.isPressed(Input.spell1):
        result &= spell1.castAt(t.pos, dir).handleSpellCast()
      if input.isPressed(Input.spell2):
        result &= spell2.castAt(t.pos, dir).handleSpellCast()
