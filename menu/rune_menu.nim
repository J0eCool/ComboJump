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
  spell_creator,
  system,
  vec,
  util

proc runeValueListNode*(pos: Vec, items: (proc(): seq[ValueKind])): Node =
  List[ValueKind](
    pos: pos,
    size: vec(12, 0),
    spacing: vec(-2),
    items: items,
    listNodesIdx: (proc(kind: ValueKind, idx: int): Node =
      let
        size = 12
        spacing = 3
      Node(
        size: vec(size, -size),
        children: newSeqOf[Node](
          SpriteNode(
            pos: vec(spacing * idx, (size + 2 - spacing) * idx),
            size: vec(size, size),
            textureName: kind.textureName,
          )
        ),
      )
    ),
  )

type
  RuneMenu* = ref object of Component
    menu: Node

proc runeMenuNode(spellData: ptr SpellData): Node =
  SpriteNode(
    pos: vec(1020, 320),
    size: vec(300, 600),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(0, -240),
        size: vec(50, 50),
        onClick: (proc() = spellData[].deleteRune()),
        children: newSeqOf[Node](
          TextNode(text: "Del")
        ),
      ),
      Button(
        pos: vec(60, -240),
        size: vec(50, 50),
        onClick: (proc() =
          for r in Rune:
            spellData[].addRuneCapacity(r)
        ),
        children: newSeqOf[Node](
          TextNode(text: "+ALL")
        ),
      ),
      List[Rune](
        spacing: vec(10),
        width: 3,
        size: vec(300, 400),
        items: (proc(): seq[Rune] = @runes.filter(proc(rune: Rune): bool = spellData[].capacity[rune] > 0)),
        listNodes: (proc(rune: Rune): Node =
          Button(
            size: vec(90, 80),
            onClick: (proc() =
              spellData[].addRune(rune)
            ),
            children: @[
              SpriteNode(
                pos: vec(-16, -12),
                size: vec(48, 48),
                textureName: rune.textureName,
              ),
              TextNode(
                pos: vec(28, 4),
                text: "[" & rune.inputString[^1..^0] & "]",
                color: color(0, 0, 0, 255),
              ),
              BindNode[int](
                item: (proc(): int = spellData[].available(rune)),
                node: (proc(count: int): Node =
                  BorderedTextNode(
                    pos: vec(28, -26),
                    text: $count,
                    color:
                      if count > 0:
                        color(255, 240, 32, 255)
                      else:
                        color(128, 128, 128, 255),
                  )
                ),
              ),
              runeValueListNode(
                vec(-22, 36),
                proc(): seq[ValueKind] =
                  rune.info.inputSeq
              ),
              TextNode(
                pos: vec(0, 28),
                text: "->",
              ),
              runeValueListNode(
                vec(20, 36),
                proc(): seq[ValueKind] =
                  rune.info.outputSeq
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
