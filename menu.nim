import
  sdl2

import
  drawing,
  input,
  option,
  rect,
  vec

type Node* = ref object of RootObj
  pos*: Vec
  size*: Vec
  parent: Node
  children*: seq[Node]

method drawSelf(node: Node, renderer: RendererPtr) =
  discard

method updateSelf(node: Node, input: InputManager) =
  discard

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

proc draw*(renderer: RendererPtr, node: Node) =
  node.updateParents()
  node.drawSelf(renderer)
  for c in node.children:
    renderer.draw(c)

proc update*(node: Node, input: InputManager) =
  node.updateParents()
  node.updateSelf(input)
  for c in node.children:
    c.update(input)


# ------

type SpriteNode* = ref object of Node

method drawSelf(sprite: SpriteNode, renderer: RendererPtr) =
  let r = rect.rect(sprite.globalPos, sprite.size)
  renderer.fillRect(r, color(128, 128, 128, 255))


# ------

type Button* = ref object of Node
  onClick*: proc()
method drawSelf(button: Button, renderer: RendererPtr) =
  let r = rect.rect(button.globalPos, button.size)
  renderer.fillRect(r, color(198, 198, 108, 255))

method updateSelf(button: Button, input: InputManager) =
  input.clickPos.bindAs click:
    let r = rect.rect(button.globalPos, button.size)
    if button.onClick != nil and r.contains click:
      button.onClick()


# ------

type List* = ref object of Node
  numItems*: proc(): int
  listNodes*: proc(i: int): Node
  generatedChildren: seq[Node]

proc generateChildren(list: List) =
  if list.generatedChildren == nil:
    list.generatedChildren = @[]
    for i in 0..<list.numItems():
      let n = list.listNodes(i)
      n.pos = vec(0.0, (n.size.y + 5.0) * i.float)
      n.parent = list
      list.generatedChildren.add n

method drawSelf(list: List, renderer: RendererPtr) =
  list.generateChildren()
  for c in list.generatedChildren:
    renderer.draw(c)

method updateSelf(list: List, input: InputManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    c.update(input)
