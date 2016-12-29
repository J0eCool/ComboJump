import
  sdl2

import
  component/sprite,
  system/render,
  drawing,
  input,
  option,
  rect,
  resources,
  vec,
  util

type Node* = ref object of RootObj
  pos*: Vec
  size*: Vec
  parent: Node
  children*: seq[Node]

method drawSelf(node: Node, renderer: RendererPtr, resources: var ResourceManager) {.base.} =
  discard

method updateSelf(node: Node, input: InputManager) {.base.} =
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

type BindNode*[T] = ref object of Node
  item*: proc(): T
  node*: proc(item: T): Node
  generated: Node
  didGenerate: bool
  cachedItem: T

proc generateChild[T](node: BindNode[T]) =
  let item = node.item()
  if not node.didGenerate or node.cachedItem != item:
    node.didGenerate = true
    node.cachedItem = item
    let n = node.node(item)
    n.parent = node
    node.generated = n

method drawSelf[T](node: BindNode[T], renderer: RendererPtr, resources: var ResourceManager) =
  node.generateChild()
  renderer.draw(node.generated, resources)

method updateSelf[T](node: BindNode[T], input: InputManager) =
  node.generateChild()
  node.generated.update(input)


# ------

type SpriteNode* = ref object of Node
  textureName*: string
  color*: Color

method drawSelf(sprite: SpriteNode, renderer: RendererPtr, resources: var ResourceManager) =
  let
    spriteImg = resources.loadSprite(sprite.textureName, renderer)
    r = rect.rect(sprite.globalPos, sprite.size)
  if spriteImg != nil:
    renderer.draw(spriteImg, r)
  else:
    renderer.fillRect(r, sprite.color)


# ------

type TextNode* = ref object of Node
  text*: string
  color*: Color

method drawSelf(text: TextNode, renderer: RendererPtr, resources: var ResourceManager) =
  renderer.drawCachedText(text.text, text.globalPos,
                          resources.loadFont("nevis.ttf"),
                          text.color)


# ------

type BorderedTextNode* = ref object of Node
  text*: string
  color*: Color

method drawSelf(text: BorderedTextNode, renderer: RendererPtr, resources: var ResourceManager) =
  let
    font = resources.loadFont("nevis.ttf")
    black = color(0, 0, 0, 255)
    borderWidth = 2
    str = text.text
    pos = text.globalPos
  for x in -1..1:
    for y in -1..1:
      if x != 0 or y != 0:
        renderer.drawCachedText(str, pos + vec(x, y) * borderWidth, font, black)
  renderer.drawCachedText(str, pos, font, text.color)


# ------

type Button* = ref object of Node
  onClick*: proc()
  isHeld: bool
  isMouseOver: bool

method drawSelf(button: Button, renderer: RendererPtr, resources: var ResourceManager) =
  let
    r = rect.rect(button.globalPos, button.size)
    c =
      if button.isMouseOver and button.isHeld:
        color(198, 198, 108, 255)
      elif button.isMouseOver:
        color(172, 172, 134, 255)
      else:
        color(160, 160, 160, 255)
  renderer.fillRect(r, c)

method updateSelf(button: Button, input: InputManager) =
  let r = rect.rect(button.globalPos, button.size)
  input.clickPressedPos.bindAs click:
    if r.contains click:
      button.isHeld = true

  button.isMouseOver = r.contains input.mousePos

  if button.isHeld:
    input.clickReleasedPos.bindAs click:
      if button.onClick != nil and r.contains click:
        button.onClick()
      button.isHeld = false
      button.isMouseOver = false


# ------

type List*[T] = ref object of Node
  items*: proc(): seq[T]
  listNodes*: proc(item: T): Node
  listNodesIdx*: proc(item: T, idx: int): Node
  spacing*: Vec
  width*: int
  horizontal*: bool
  generatedChildren: seq[Node]
  cachedItems: seq[T]

proc indexOffset(i, width: int, mainDir: bool): int =
  if width == 0:
    if mainDir:
      i
    else:
      0
  else:
    if mainDir:
      i div width
    else:
      i mod width

proc generateChildren[T](list: List[T]) =
  assert list.listNodes != nil xor list.listNodesIdx != nil, "List must have exactly one of listNodes or listNodesIdx"
  let
    items = list.items()
    nodeProc =
      if list.listNodes != nil:
        proc(idx: int): Node =
          list.listNodes(items[idx])
      else:
        proc(idx: int): Node =
          list.listNodesIdx(items[idx], idx)
  if list.cachedItems != items:
    list.cachedItems = items
    list.generatedChildren = @[]
    for i in 0..<items.len:
      let
        n = nodeProc(i)
        s = n.size + list.spacing
        x = indexOffset(i, list.width, list.horizontal)
        y = indexOffset(i, list.width, not list.horizontal)
      n.pos = (vec(x, y) + vec(0.5)) * s - list.size / 2
      n.parent = list
      list.generatedChildren.add n

method drawSelf[T](list: List[T], renderer: RendererPtr, resources: var ResourceManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    renderer.draw(c, resources)

method updateSelf[T](list: List[T], input: InputManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    c.update(input)
