from sdl2 import RendererPtr
import
  strutils,
  typetraits

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
    queuedMenus: seq[proc(m: var MenuManager)]

  Menu*[M, C] = ref object of RootObj
    model*: M
    controller*: C
    view*: proc(model: M, controller: C): Node
    update*: proc(model: M, controller: C, dt: float, input: InputManager)
    node: Node

  MenuBase* = Menu[ref RootObj, Controller]

  MenuManager* = object
    focusedNode*: Node
    menus*: Stack[MenuBase]
    toAdd: seq[MenuBase]

proc baseDiff(node, newVal: Node) =
  node.pos = newVal.pos
  node.size = newVal.size

method typeName(node: Node): string {.base.} =
  "Node"

method diffSelf(node, newVal: Node) {.base.} =
  node.baseDiff(newVal)

method drawSelf(node: Node, renderer: RendererPtr, resources: ResourceManager) {.base.} =
  discard

method updateSelf(node: Node, manager: var MenuManager, input: InputManager) {.base.} =
  discard

method getChildren(node: Node): seq[Node] {.base.} =
  node.children

proc updateParents(node: Node) =
  for c in node.getChildren():
    c.parent = node
    c.updateParents()

proc globalPos*(node: Node): Vec =
  result = node.pos
  var cur = node.parent
  while cur != nil:
    result += cur.pos
    cur = cur.parent

proc draw*(renderer: RendererPtr, node: Node, resources: ResourceManager) =
  node.updateParents()
  node.drawSelf(renderer, resources)
  for c in node.getChildren():
    renderer.draw(c, resources)

proc update*(node: Node, manager: var MenuManager, input: InputManager) =
  node.updateParents()
  node.updateSelf(manager, input)
  for c in node.getChildren():
    c.update(manager, input)

proc diff*[T: Node](node: var T, newVal: T) =
  if node == nil or node.typeName != newVal.typeName:
    node = newVal
    return
  node.diffSelf(newVal)
  if node.children.len != newVal.children.len:
    node.children = newVal.children
    return
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

method drawSelf[T](node: BindNode[T], renderer: RendererPtr, resources: ResourceManager) =
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

method typeName(sprite: SpriteNode): string =
  "SpriteNode"

method diffSelf(sprite, newVal: SpriteNode) =
  sprite.baseDiff(newVal)
  sprite.textureName = newVal.textureName
  sprite.color = newVal.color
  sprite.scale = newVal.scale

method drawSelf(sprite: SpriteNode, renderer: RendererPtr, resources: ResourceManager) =
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
  fontSize*: int

method typeName(text: TextNode): string =
  "TextNode"

method diffSelf(text, newVal: TextNode) =
  text.baseDiff(newVal)
  text.text = newVal.text
  text.color = newVal.color

method drawSelf(text: TextNode, renderer: RendererPtr, resources: ResourceManager) =
  if text.fontSize == 0:
    text.fontSize = 24
  let font = resources.loadFont("nevis.ttf", text.fontSize)
  renderer.drawCachedText(text.text, text.globalPos, font, text.color)


# ------

type BorderedTextNode* = ref object of TextNode

method drawSelf(text: BorderedTextNode, renderer: RendererPtr, resources: ResourceManager) =
  if text.color == rgba(0, 0, 0, 0):
    # default color to white
    text.color = rgb(255, 255, 255)
  if text.fontSize == 0:
    text.fontSize = 24
  let font = resources.loadFont("nevis.ttf", text.fontSize)
  renderer.drawBorderedText(text.text, text.globalPos, font, text.color)

# ------

type Button* = ref object of Node
  label*: string
  onClick*: proc()
  hotkey*: Input
  color*: Color
  hoverNode*: Node
  invisible*: bool
  isHeld: bool
  isMouseOver: bool
  isKeyHeld: bool

method typeName(button: Button): string =
  "Button"

method diffSelf(button, newVal: Button) =
  button.baseDiff(newVal)
  button.label = newVal.label
  button.onClick = newVal.onClick
  button.hotkey = newVal.hotkey
  button.color = newVal.color
  button.invisible = newVal.invisible

  if button.hoverNode != nil:
    button.hoverNode.diff(newVal.hoverNode)

method drawSelf(button: Button, renderer: RendererPtr, resources: ResourceManager) =
  if button.invisible:
    return

  let
    baseColor =
      if button.color.a == 0:
        rgb(160, 160, 160)
      else:
        button.color
    c =
      if button.onClick == nil:
        baseColor
      elif (button.isMouseOver and button.isHeld) or button.isKeyHeld:
        baseColor.average rgb(255, 255, 192)
      elif button.isMouseOver:
        baseColor.average rgb(198, 198, 92)
      else:
        baseColor
  renderer.fillRect(button.rect, c)

  if button.label != nil:
    let font = resources.loadFont("nevis.ttf")
    renderer.drawBorderedText(button.label, button.globalPos, font, white)

method getChildren(button: Button): seq[Node] =
  result = button.children
  if button.hoverNode != nil and button.isMouseOver:
      result.safeAdd button.hoverNode

method updateSelf(button: Button, manager: var MenuManager, input: InputManager) =
  let r = button.rect
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

  if button.hotkey != Input.none and button.onClick != nil:
    if not button.isKeyHeld and input.isPressed(button.hotkey):
      button.isKeyHeld = true
    elif button.isKeyHeld and input.isReleased(button.hotkey):
      button.isKeyHeld = false
      button.onClick()


# ------

type List*[T] = ref object of Node
  items*: seq[T]
  listNodes*: proc(item: T): Node
  listNodesIdx*: proc(item: T, idx: int): Node
  spacing*: Vec
  width*: int
  horizontal*: bool
  ignoreSpacing*: bool
  generatedChildren: seq[Node]

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
  if list.generatedChildren != nil:
    return

  assert(list.listNodes == nil or list.listNodesIdx == nil,
         "List must have no more than one nodes proc")
  let
    items = list.items
    nodeProc =
      if list.listNodes != nil:
        proc (idx: int): Node =
          list.listNodes(items[idx])
      else:
        proc (idx: int): Node =
          list.listNodesIdx(items[idx], idx)
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

proc toStr*(t: typedesc): string =
  # For some reason this proc needs to exist to avoid requiring List[T] users to
  # also import typetraits
  name(t)
method typeName[T](list: List[T]): string =
  "List[" & T.toStr & "]"

method diffSelf[T](list, newVal: List[T]) =
  newVal.generateChildren()
  if list.items != newVal.items:
    list.items = newVal.items
    list.generatedChildren = newVal.generatedChildren
  else:
    list.generateChildren()
    for i in 0..<list.items.len:
      list.generatedChildren[i].diff(newVal.generatedChildren[i])
  list.baseDiff(newVal)

method getChildren[T](list: List[T]): seq[Node] =
  list.generateChildren()
  let children = if list.children == nil: @[] else: list.children
  children & list.generatedChildren


# ------

type InputTextNode* = ref object of Node
  str*: ptr string
  num*: ptr int
  onChange*: proc()
  buffer: string
  isFocused: bool

proc focus(manager: var MenuManager, text: InputTextNode) =
  manager.focusedNode = text
  if text.str != nil:
    text.buffer = text.str[]
  else:
    text.buffer = $text.num[]

proc unfocus(manager: var MenuManager, text: InputTextNode) =
  manager.focusedNode = nil
  text.buffer = nil

method updateSelf(text: InputTextNode, manager: var MenuManager, input: InputManager) =
  let r = text.rect
  input.clickPressedPos.bindAs click:
    if r.contains click:
      manager.focus(text)
    elif manager.focusedNode == text:
      manager.unfocus(text)
  if manager.focusedNode == text:
    if input.isPressed(Input.escape):
      manager.unfocus(text)
    if input.isPressed(Input.enter):
      if text.str != nil:
        text.str[] = text.buffer
      else:
        text.num[] = text.buffer.parseInt
      if text.onChange != nil:
        text.onChange()
      manager.unfocus(text)

  text.isFocused = (manager.focusedNode == text)
  if text.isFocused:
    discard handleTextInput(
        text.buffer, input,
        ignoreLetters = (text.str == nil),
      )

method drawSelf(text: InputTextNode, renderer: RendererPtr, resources: ResourceManager) =
  var baseRect = text.rect
  let
    font = resources.loadFont("nevis.ttf")
    str =
      if text.isFocused:
        text.buffer & "|"
      elif text.str != nil:
        text.str[]
      else:
        $text.num[]
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

proc stringListNode*(lines: seq[string], pos = vec(0), fontSize = 24): Node =
  List[string](
    pos: pos,
    spacing: vec(0, fontSize + 1),
    items: lines,
    listNodes: (proc(line: string): Node =
      BorderedTextNode(
        text: line,
        color: rgb(255, 255, 255),
        fontSize: fontSize,
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
    update: (proc(model: ref RootObj, controller: Controller, dt: float, input: InputManager) =
      if menu.update != nil:
        menu.update(cast[M](model), cast[C](controller), dt, input)
    ),
  )

method shouldDrawBelow*(controller: Controller): bool {.base.} =
  false

method shouldUpdateBelow*(controller: Controller): bool {.base.} =
  false

proc push*[M, C](menus: var MenuManager, menu: Menu[M, C]) =
  menus.menus.push(downcast[M, C](menu))

proc pop*(menus: var MenuManager) =
  discard menus.menus.pop()

proc queueMenu*(controller: Controller, menu: MenuBase) =
  controller.queuedMenus.safeAdd(proc(menus: var MenuManager) =
    menus.push(menu)
  )

proc runUpdate*(menu: Menu, manager: var MenuManager, dt: float, input: InputManager) =
  menu.update(menu.model, menu.controller, dt, input)
  let newNode = menu.view(menu.model, menu.controller)
  menu.node.diff(newNode)
  menu.node.update(manager, input)

proc draw*(renderer: RendererPtr, menu: Menu, resources: ResourceManager) =
  if menu.node != nil:
    renderer.draw(menu.node, resources)

proc newMenuManager*(): MenuManager =
  MenuManager(
    menus: newStack[MenuBase](),
  )

proc update*(menus: var MenuManager, dt: float, input: InputManager) =
  for menu in menus.menus.mitems:
    menu.runUpdate(menus, dt, input)

    let
      toPush = menu.controller.queuedMenus
      isTop = menu == menus.menus.peek()
      shouldPop = menu.controller.shouldPop and isTop and toPush.len == 0
    if shouldPop:
      menus.pop()
      menus.menus.mpeek().runUpdate(menus, 0.0, input)
    if toPush != nil:
      for p in toPush:
        p(menus)
        menus.menus.mpeek().runUpdate(menus, 0.0, input)
      break
    if shouldPop or not menu.controller.shouldUpdateBelow:
      break
    menu.controller.queuedMenus = @[]
  while menus.menus.peek().controller.shouldPop:
    menus.pop()

proc draw*(renderer: RendererPtr, menus: MenuManager, resources: ResourceManager) =
  var toDraw = newStack[MenuBase]()
  for menu in menus.menus:
    toDraw.push(menu)
    if not menu.controller.shouldDrawBelow:
      break
  for menu in toDraw:
    renderer.draw(menu, resources)

proc nodes*(children: seq[Node]): Node =
  Node(children: children)
