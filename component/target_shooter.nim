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
  spell_creator,
  resources,
  system,
  targeting,
  vec,
  util

type
  TargetShooter* = ref object of Component


let
  fireInputs = [jump, spell1, spell2, spell3]

proc inputString(input: Input): string =
  case input
  of jump:
    return "K"
  of spell1:
    return "J"
  of spell2:
    return "I"
  of spell3:
    return "L"
  else:
    assert false, "Unexpected input string"

let
  varSpellMenu = List[int](
    pos: vec(20, 680),
    spacing: vec(4),
    items: (proc(): seq[int] = toSeq(0..<getSpells().len)),
    listNodes: (proc(descIdx: int): Node =
      SpriteNode(
        size: vec(810, 48),
        color: color(128, 128, 128, 255),
        children: @[
          BindNode[int](
            pos: vec(-375, -12),
            item: (proc(): int =
              if descIdx != getVarSpell():
                -1
              else:
                getVarSpellIdx()
            ),
            node: (proc(idx: int): Node =
              if idx == -1:
                Node()
              else:
                SpriteNode(
                  pos: vec(20 * idx, 12),
                  size: vec(4, 30),
                )
            ),
          ),
          TextNode(
            pos: vec(-390, 0),
            text: fireInputs[descIdx].inputString & ":",
          ),
          List[Rune](
            spacing: vec(-4, 0),
            horizontal: true,
            pos: vec(25, 0),
            size: vec(800, 24),
            items: (proc(): seq[Rune] = getSpellDesc(descIdx)),
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
  priority = -100
  proc drawSpells*(resources: var ResourceManager) =
    renderer.draw(varSpellMenu, resources)

defineSystem:
  proc targetedShoot*(input: InputManager, camera: Camera) =
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

      for i in 0..<getSpells().len:
        if input.isPressed(fireInputs[i]):
          result &= getSpells()[i].handleSpellCast(t.pos, dir, targeting.target)
