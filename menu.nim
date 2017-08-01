from sdl2 import RendererPtr

import
  component/sprite,
  system/render,
  color,
  drawing,
  input,
  option,
  rect,
  resources,
  stack,
  vec,
  util

type
  Node* = ref object of RootObj
    pos*: Vec
    size*: Vec
    parent: Node
    children*: seq[Node]

  Controller* = ref object of RootObj
    name*: string
    shouldPop*: bool

  Menu*[M, C] = ref object
    model*: M
    controller*: C
    view*: proc(model: M, controller: C): Node
    node: Node

  MenuBase* = Menu[ref RootObj, Controller]
  MenuManager* = object
    focusedNode*: Node
    menus*: Stack[MenuBase]
    toAdd: seq[MenuBase]

proc baseDiff(node, newVal: Node) =
  node.pos = newVal.pos
  node.size = newVal.size

method diffSelf(node, newVal: Node): bool {.base.} =
  node.baseDiff(newVal)
  node.children.len == newVal.children.len

method drawSelf(node: Node, renderer: RendererPtr, resources: var ResourceManager) {.base.} =
  discard

method updateSelf(node: Node, manager: var MenuManager, input: InputManager) {.base.} =
  discard

proc updateParents(node: Node) =
  for c in node.children:
    c.parent = node
    c.updateParents()

proc globalPos*(node: Node): Vec =
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

proc update*(node: Node, manager: var MenuManager, input: InputManager) =
  node.updateParents()
  node.updateSelf(manager, input)
  for c in node.children:
    c.update(manager, input)

proc diff(node: var Node, newVal: Node) =
  if not node.diffSelf(newVal):
    node = newVal
  for i in 0..<node.children.len:
    node.children[i].diff(newVal.children[i])

proc rect*(node: Node): Rect =
  rect.rect(node.globalPos, node.size)

proc contains*(node: Node, pos: Vec): bool =
  node.rect.contains(pos)

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

method updateSelf[T](node: BindNode[T], manager: var MenuManager, input: InputManager) =
  node.generateChild()
  node.generated.update(manager, input)


# ------

type SpriteNode* = ref object of Node
  textureName*: string
  color*: Color
  scale*: float

method diffSelf(sprite, newVal: SpriteNode): bool =
  sprite.baseDiff(newVal)
  sprite.textureName = newVal.textureName
  sprite.color = newVal.color
  sprite.scale = newVal.scale
  true

method drawSelf(sprite: SpriteNode, renderer: RendererPtr, resources: var ResourceManager) =
  let spriteImg = resources.loadSprite(sprite.textureName, renderer)
  if sprite.size == vec() and sprite.scale != 0.0:
    sprite.size = spriteImg.size.size * sprite.scale
  let r = rect.rect(sprite.globalPos, sprite.size)
  if spriteImg != nil:
    renderer.draw(spriteImg, r)
  else:
    renderer.fillRect(r, sprite.color)


# ------

type TextNode* = ref object of Node
  text*: string
  color*: Color

method diffSelf(text, newVal: TextNode): bool =
  text.baseDiff(newVal)
  text.text = newVal.text
  text.color = newVal.color
  true

method drawSelf(text: TextNode, renderer: RendererPtr, resources: var ResourceManager) =
  let font = resources.loadFont("nevis.ttf")
  renderer.drawCachedText(text.text, text.globalPos, font, text.color)


# ------

type BorderedTextNode* = ref object of TextNode

method drawSelf(text: BorderedTextNode, renderer: RendererPtr, resources: var ResourceManager) =
  if text.color == rgba(0, 0, 0, 0):
    # default color to white
    text.color = rgb(255, 255, 255)
  let font = resources.loadFont("nevis.ttf")
  renderer.drawBorderedText(text.text, text.globalPos, font, text.color)

# ------

type Button* = ref object of Node
  # TODO: just give buttons labels already goddammit
  onClick*: proc()
  hotkey*: Input
  color*: Color
  isHeld: bool
  isMouseOver: bool
  isKeyHeld: bool

method diffSelf(button, newVal: Button): bool =
  button.baseDiff(newVal)
  true

method drawSelf(button: Button, renderer: RendererPtr, resources: var ResourceManager) =
  let
    baseColor =
      if button.color.a == 0:
        rgb(160, 160, 160)
      else:
        button.color
    c =
      if (button.isMouseOver and button.isHeld) or button.isKeyHeld:
        baseColor.average rgb(255, 255, 192)
      elif button.isMouseOver:
        baseColor.average rgb(198, 198, 92)
      else:
        baseColor
  renderer.fillRect(button.rect, c)

method updateSelf(button: Button, manager: var MenuManager, input: InputManager) =
  if button.onClick == nil:
    return

  let r = button.rect
  input.clickPressedPos.bindAs click:
    if r.contains click:
      button.isHeld = true

  button.isMouseOver = r.contains input.mousePos

  if button.isHeld:
    input.clickReleasedPos.bindAs click:
      if r.contains click:
        button.onClick()
      button.isHeld = false
      button.isMouseOver = false

  if button.hotkey != Input.none:
    if not button.isKeyHeld and input.isPressed(button.hotkey):
      button.isKeyHeld = true
      button.onClick()
    elif button.isKeyHeld and input.isReleased(button.hotkey):
      button.isKeyHeld = false


# ------

type List*[T] = ref object of Node
  items*: proc(): seq[T]
  listNodes*: proc(item: T): Node
  listNodesIdx*: proc(item: T, idx: int): Node
  spacing*: Vec
  width*: int
  horizontal*: bool
  ignoreSpacing*: bool
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
      n.pos =
        if list.ignoreSpacing:
          n.pos
        else:
          n.pos + (vec(x, y) + vec(0.5)) * s - list.size / 2
      n.parent = list
      list.generatedChildren.add n

method drawSelf[T](list: List[T], renderer: RendererPtr, resources: var ResourceManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    renderer.draw(c, resources)

method updateSelf[T](list: List[T], manager: var MenuManager, input: InputManager) =
  list.generateChildren()
  for c in list.generatedChildren:
    c.update(manager, input)


# ------

type InputTextNode* = ref object of Node
  text*: ptr string
  ignoreLetters*: bool
  ignoreNumbers*: bool
  isFocused: bool

method updateSelf(text: InputTextNode, manager: var MenuManager, input: InputManager) =
  let r = text.rect
  input.clickPressedPos.bindAs click:
    if r.contains click:
      manager.focusedNode = text
    elif manager.focusedNode == text:
      manager.focusedNode = nil
  if manager.focusedNode == text and input.isPressed(Input.escape):
    manager.focusedNode = nil

  text.isFocused = (manager.focusedNode == text)
  if text.isFocused:
    discard handleTextInput(
        text.text[], input,
        ignoreLetters = text.ignoreLetters,
        ignoreNumbers = text.ignoreNumbers
      )

method drawSelf(text: InputTextNode, renderer: RendererPtr, resources: var ResourceManager) =
  var baseRect = text.rect
  let
    font = resources.loadFont("nevis.ttf")
    str =
      if text.isFocused:
        text.text[] & "|"
      else:
        text.text[]
    borderWidth = 2.0
    inBorderRect = rect(baseRect.pos, baseRect.size - vec(borderWidth * 2.0))
    borderColor =
      if text.isFocused:
        color.yellow
      else:
        color.black
  renderer.fillRect(baseRect, borderColor)
  renderer.fillRect(inBorderRect, rgb(160, 160, 160))
  renderer.drawBorderedText(str, text.globalPos, font, color.white)


# ------

proc stringListNode*(lines: seq[string], pos = vec(0)): Node =
  List[string](
    pos: pos,
    spacing: vec(0, 25),
    items: (proc(): seq[string] = lines),
    listNodes: (proc(line: string): Node =
      BorderedTextNode(
        text: line,
        color: rgb(255, 255, 255),
      )
    ),
  )

# ------

proc downcast*[M, C](menu: Menu[M, C]): MenuBase =
  MenuBase(
    model: cast[ref RootObj](menu.model),
    controller: cast[Controller](menu.controller),
    view: (proc(model: ref RootObj, controller: Controller): Node =
      menu.view(cast[M](model), cast[C](controller))
    ),
  )

method update*(controller: Controller, dt: float) {.base.} =
  discard

method shouldDrawBelow*(controller: Controller): bool {.base.} =
  false

method shouldUpdateBelow*(controller: Controller): bool {.base.} =
  false

method pushMenus*(controller: Controller): seq[MenuBase] {.base.} =
  nil

proc push*[M, C](menus: var MenuManager, menu: Menu[M, C]) =
  menus.menus.push(downcast[M, C](menu))

proc pop*(menus: var MenuManager) =
  discard menus.menus.pop()

proc update*(menu: Menu, manager: var MenuManager, dt: float, input: InputManager) =
  menu.controller.update(dt)
  # TODO: more sophisticated virtualDom-style diffing
  # TODO: diffing unit tests
  let newNode = menu.view(menu.model, menu.controller)
  if menu.node == nil:
    menu.node = newNode
  else:
    menu.node.diff(newNode)
  menu.node.update(manager, input)

proc draw*(renderer: RendererPtr, menu: Menu, resources: var ResourceManager) =
  if menu.node != nil:
    renderer.draw(menu.node, resources)

proc newMenuManager*(): MenuManager =
  MenuManager(
    menus: newStack[MenuBase](),
  )

proc update*(menus: var MenuManager, dt: float, input: InputManager) =
  for menu in menus.menus.mitems:
    menu.update(menus, dt, input)

    let
      toPush = menu.controller.pushMenus()
      isTop = menu == menus.menus.peek()
      shouldPop = menu.controller.shouldPop and isTop
    if shouldPop:
      menus.pop()
      menus.menus.mpeek().update(menus, 0.0, input)
    if toPush != nil:
      for p in toPush:
        menus.push(p)
        menus.menus.mpeek().update(menus, 0.0, input)
    if shouldPop or not menu.controller.shouldUpdateBelow:
      break
  while menus.menus.peek().controller.shouldPop:
    menus.pop()

proc draw*(renderer: RendererPtr, menus: MenuManager, resources: var ResourceManager) =
  var toDraw = newStack[MenuBase]()
  for menu in menus.menus:
    toDraw.push(menu)
    if not menu.controller.shouldDrawBelow:
      break
  for menu in toDraw:
    renderer.draw(menu, resources)
