import
  sdl2,
  sequtils

import
  component/mana,
  component/targeting,
  component/target_shooter,
  component/transform,
  menu/rune_menu,
  entity,
  event,
  input,
  menu,
  newgun,
  option,
  player_stats,
  spell_creator,
  resources,
  system,
  vec,
  util

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

type
  SpellHudMenu* = ref object of Component
    menu: Node

type SpellStats = tuple[spell: SpellParse, stats: PlayerStats]

proc spellHudMenuNode(spellData: ptr SpellData, stats: ptr PlayerStats, targetShooter: TargetShooter): Node =
  List[int](
    pos: vec(20, 680),
    spacing: vec(4),
    items: (proc(): seq[int] = toSeq(0..<spellData.spells.len)),
    listNodes: (proc(descIdx: int): Node =
      SpriteNode(
        size: vec(810, 48),
        color: color(128, 128, 128, 255),
        children: @[
          BindNode[SpellStats](
            item: (proc(): SpellStats = (spellData.spells[descIdx], stats[])),
            node: (proc(pair: SpellStats): Node =
              case pair.spell.kind
              of error:
                SpriteNode(
                  pos: vec(-365 + 20 * pair.spell.index, 0),
                  size: vec(30, 30),
                  color: color(255, 0, 0, 255),
                )
              of success:
                Node(
                  children: @[
                    BindNode[float](
                      item: (proc(): float =
                        if targetShooter.castIndex != descIdx or targetShooter.toCast.kind == error:
                          0.0
                        else:
                          1.0 - targetShooter.castTime / targetShooter.toCast.castTime(pair.stats)
                      ),
                      node: (proc(pct: float): Node =
                        SpriteNode(
                          size: vec(810 * pct, 48),
                          color: color(32, 240, 240, 255),
                        )
                      ),
                    ),
                    BorderedTextNode(
                      pos: vec(330, -13),
                      text: "Cost: " & $pair.spell.manaCost,
                      color: color(32, 240, 240, 255),
                    ).Node,
                    BorderedTextNode(
                      pos: vec(280, 13),
                      text: "Cast Time: " & formatFloat(pair.spell.castTime(pair.stats)) & "s",
                      color: color(32, 240, 240, 255),
                    ),
                  ],
                )
            ),
          ),
          BindNode[int](
            pos: vec(-375, -12),
            item: (proc(): int =
              if descIdx != spellData.varSpell:
                -1
              else:
                spellData.varSpellIdx
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
            items: (proc(): seq[Rune] = spellData.spellDescs[descIdx]),
            listNodesIdx: (proc(rune: Rune, runeIdx: int): Node =
              SpriteNode(
                size: vec(24, 24),
                textureName: rune.textureName,
                children: newSeqOf[Node](
                  runeValueListNode(
                    vec(0, -12),
                    proc(): seq[ValueKind] =
                      let stacks = spellData.spells[descIdx].valueStacks
                      if runeIdx < stacks.len:
                        stacks[runeIdx]
                      else:
                        @[]
                  )
                ),
              )
            ),
          ),
        ],
      )
    ),
  )

defineDrawSystem:
  priority = -100
  proc drawSpellHudMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      SpellHudMenu, spellHudMenu,
    ]:
      renderer.draw(spellHudMenu.menu, resources)

defineSystem:
  proc updateSpellHudMenu*(input: InputManager, spellData: var SpellData, stats: var PlayerStats) =
    entities.forComponents entity, [
      SpellHudMenu, spellHudMenu,
    ]:
      if spellHudMenu.menu == nil:
        entities.forComponents entity, [
          TargetShooter, targetShooter,
        ]:
          spellHudMenu.menu = spellHudMenuNode(addr spellData, addr stats, targetShooter)
          break
      spellHudMenu.menu.update(input)
