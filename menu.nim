import
  sdl2

import
  drawing,
  input,
  option,
  rect,
  vec

type
  Node* = ref object of RootObj
    pos*: Vec
    size*: Vec
    parent: Node
    children*: seq[Node]
  SpriteNode* = ref object of Node
  Button* = ref object of Node
    onClick*: proc()

proc updateParents(node: Node) =
  for c in node.children:
    c.parent = node
    c.updateParents()

proc globalPos(node: Node): Vec =
  result = node.pos
  var cur = node.parent
  while cur != nil:
    result += cur.pos
    cur = cur.parent

method drawSelf(node: Node, renderer: RendererPtr) =
  discard

proc draw*(renderer: RendererPtr, node: Node) =
  node.updateParents()
  node.drawSelf(renderer)
  for c in node.children:
    renderer.draw(c)

method drawSelf(sprite: SpriteNode, renderer: RendererPtr) =
  let r = rect.rect(sprite.globalPos, sprite.size)
  renderer.fillRect(r, color(128, 128, 128, 255))

method drawSelf(button: Button, renderer: RendererPtr) =
  let r = rect.rect(button.globalPos, button.size)
  renderer.fillRect(r, color(198, 198, 108, 255))

method updateSelf(node: Node, input: InputManager) =
  discard

proc update*(node: Node, input: InputManager) =
  node.updateParents()
  node.updateSelf(input)
  for c in node.children:
    c.update(input)

method updateSelf(button: Button, input: InputManager) =
  input.clickPos.bindAs click:
    let r = rect.rect(button.globalPos, button.size)
    if button.onClick != nil and r.contains click:
      button.onClick()
