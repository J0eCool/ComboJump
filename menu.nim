import
  sdl2

import
  component/sprite,
  drawing,
  input,
  option,
  rect,
  resources,
  vec

type Node* = ref object of RootObj
  pos*: Vec
  size*: Vec
  parent: Node
  children*: seq[Node]

method drawSelf(node: Node, renderer: RendererPtr, resources: var ResourceManager) =
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

proc draw*(renderer: RendererPtr, node: Node, resources: var ResourceManager) =
  node.updateParents()
  node.drawSelf(renderer, resources)
  for c in node.children:
    renderer.draw(c, resources)

proc update*(node: Node, input: InputManager) =
  node.updateParents()
  node.updateSelf(input)
  for c in node.children:
    c.update(input)


# ------

type SpriteNode* = ref object of Node
  textureName*: string

method drawSelf(sprite: SpriteNode, renderer: RendererPtr, resources: var ResourceManager) =
  let
    spriteImg = resources.loadSprite(sprite.textureName, renderer)
    r = rect.rect(sprite.globalPos, sprite.size)
  if spriteImg != nil:
    renderer.draw(spriteImg, r)
  else:
    renderer.fillRect(r, color(128, 128, 128, 255))


# ------

type Button* = ref object of Node
  onClick*: proc()

method drawSelf(button: Button, renderer: RendererPtr, resources: var ResourceManager) =
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
  spacing*: Vec
  width*: int
  generatedChildren: seq[Node]

proc generateChildren(list: List) =
  if list.generatedChildren == nil:
    list.generatedChildren = @[]
    for i in 0..<list.numItems():
      let
        n = list.listNodes(i)
        s = n.size + list.spacing
        x = if list.width != 0: i mod list.width else: 0
        y = if list.width != 0: i div list.width else: i
      n.pos = (vec(x, y) + vec(0.5)) * s - list.size / 2
      n.parent = list
      list.generatedChildren.add n

method drawSelf(list: List, renderer: RendererPtr, resources: var ResourceManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    renderer.draw(c, resources)

method updateSelf(list: List, input: InputManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    c.update(input)
