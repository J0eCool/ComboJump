import
  hashes,
  sdl2,
  sequtils,
  tables,
  typetraits

import
  system/[
    render,
  ],
  camera,
  color,
  entity,
  event,
  input,
  jsonparse,
  menu,
  logging,
  option,
  program,
  rect,
  resources,
  stack,
  util,
  vec

const savedCodeFile = "qlang_code.json"

type
  Value = int # TODO: non-int values
  VariableValues = Table[string, Value]
  Execution = object
    output: seq[string]
    variables: VariableValues # TODO: Stack of scopes

proc newExecution(): Execution =
  Execution(
    output: @[],
    variables: initTable[string, Value](),
  )

proc getValue(execution: Execution, varName: string): Value =
  for name, value in execution.variables:
    if name == varName:
      return value

type
  ASTNodeObj = object of RootObj
    dirty: bool
  ASTNode = ref ASTNodeObj
  ExprNodeObj = object of ASTNode
  ExprNode = ref ExprNodeObj
  StmtNodeObj = object of ASTNode
  StmtNode = ref StmtNodeObj

var astKindConstructors = initTable[string, (proc(): ASTNode)]()
method fromJSON_impl(node: ASTNode, json: JSON)

template astJson(t, p: untyped) =
  autoObjectJSONProcs(t, @["dirty"])
  astKindConstructors[p.type.name] = (proc(): ASTNode = new p)
  method toJSON(node: p): JSON =
    result = toJSON(node[])
    assert result.kind == jsObject
    result.obj["_kind"] = JSON(kind: jsString, str: p.type.name)
  method fromJSON_impl(node: p, json: JSON) =
    echo "Loading in kind ", p.type.name
    fromJSON(node[], json)

proc fromJSON[T: ASTNode](node: var T, json: JSON) =
  echo "Loading from json: ", json
  assert json.kind == jsObject
  let kindJson = json.obj["_kind"]
  assert kindJson.kind == jsString
  let constructor = astKindConstructors[kindJson.str]
  node = cast[T](constructor())
  fromJSON_impl(node, json)

astJson(ASTNodeObj, ASTNode)
astJson(ExprNodeObj, ExprNode)
astJson(StmtNodeObj, StmtNode)

var selected: ASTNode = nil # TODO: Not global!
proc selectedColor(node: ASTNode, baseColor: color.Color): color.Color =
  if node == selected:
    color.lightYellow
  else:
    baseColor

method size(node: ASTNode): Vec {.base.} =
  vec()
method menuSelf(node: ASTNode, pos: Vec): Node {.base.} =
  Node()
proc menu(node: ASTNode, pos: Vec): Node =
  BindNode[bool](
    item: (proc(): bool = node.dirty),
    node: (proc(_: bool): Node =
      node.dirty = false
      node.menuSelf(pos)
    ),
  )
method children(node: ASTNode): seq[ASTNode] {.base.} =
  @[]
method handleInput(node: ASTNode, input: InputManager) {.base.} =
  discard
method addNode(node: ASTNode, toAdd: ASTNode): bool {.base.} =
  false
method replaceOnAdd(node: ASTNode): bool {.base.} =
  false
method replaceChild(node: ASTNode, child, toAdd: ASTNode): bool {.base.} =
  false
method removeChild(node: ASTNode, child: ASTNode) {.base.} =
  discard

proc flattenedNodes(ast: ASTNode): seq[ASTNode] =
  result = @[ast]
  for node in ast.children:
    result.add flattenedNodes(node)

method execute(statement: StmtNode, execution: var Execution) {.base.} =
  discard
method eval(expression: ExprNode, execution: Execution): Value {.base.} =
  0

proc bodyNode(ast: ASTNode, size: Vec, color: color.Color, children: seq[Node] = @[]): Node =
  const borderWidth = 1.0
  SpriteNode(
    size: size + vec(2 * borderWidth),
    color: black,
    children: @[
      Button(
        size: size,
        color: ast.selectedColor(color),
        onClick: (proc() =
          selected = ast
        ),
        children: children,
      ).Node,
    ],
  )

type
  EmptyObj = object of ExprNode
  Empty = ref EmptyObj

astJson(EmptyObj, Empty)

method size(empty: Empty): Vec =
  vec(24)
method menuSelf(empty: Empty, pos: Vec): Node =
  result = empty.bodyNode(empty.size, color.lightGray)
  result.pos = pos
method replaceOnAdd(empty: Empty): bool =
  true

type
  Literal = ref LiteralObj
  LiteralObj = object of ExprNode
    value: int

astJson(LiteralObj, Literal)

method size(literal: Literal): Vec =
  vec(36)
method menuSelf(literal: Literal, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      literal.bodyNode(literal.size, color.lightGray),
      BorderedTextNode(
        text: $literal.value,
      ),
    ],
  )
method eval(literal: Literal, execution: Execution): Value =
  literal.value
method handleInput(literal: Literal, inputMan: InputManager) =
  if inputMan.isHeld(Input.ctrl):
    return
  for idx in 0..<input.allNumbers.len:
    let button = input.allNumbers[idx]
    if inputMan.isPressed(button):
      literal.value *= 10
      literal.value += idx
      literal.dirty = true
  if inputMan.isPressed(Input.backspace):
    literal.value = literal.value div 10
    literal.dirty = true
  if inputMan.isPressed(Input.delete):
    literal.value = 0
    literal.dirty = true

type
  Variable = ref VariableObj
  VariableObj = object of ExprNode
    ident: string

astJson(VariableObj, Variable)

method size(variable: Variable): Vec =
  vec(64, 36)
method menuSelf(variable: Variable, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      variable.bodyNode(variable.size, color.lightGray),
      BorderedTextNode(
        text: variable.ident,
      ),
    ],
  )
method eval(variable: Variable, execution: Execution): Value =
  execution.getValue(variable.ident)
method handleInput(variable: Variable, inputMan: InputManager) =
  if inputMan.isHeld(Input.ctrl):
    return
  for idx in 0..<input.allLetters.len:
    let key = input.allLetters[idx]
    if inputMan.isPressed(key):
      variable.ident &= key.letterKeyStr
      variable.dirty = true
  if inputMan.isPressed(Input.backspace):
    variable.ident = variable.ident[0..<variable.ident.len-1]
    variable.dirty = true
  if inputMan.isPressed(Input.delete):
    variable.ident = ""
    variable.dirty = true

type
  VariableAssign = ref VariableAssignObj
  VariableAssignObj = object of StmtNode
    variable: Variable
    value: ExprNode

astJson(VariableAssignObj, VariableAssign)

method size(assign: VariableAssign): Vec =
  assign.value.size + vec(110, 6)
method menuSelf(assign: VariableAssign, pos: Vec): Node =
  # TODO: reuse infix logic from binary exprs
  Node(
    pos: pos,
    children: @[
      assign.bodyNode(assign.size, color.gray),
      assign.variable.menu(vec((assign.variable.size.x - assign.size.x) / 2 + 2, 0)),
      BorderedTextNode(
        pos: vec(0, 0),
        text: ":=",
      ),
      assign.value.menu(vec((assign.size.x - assign.value.size.x) / 2 - 2, 0)),
    ],
  )
method execute(assign: VariableAssign, execution: var Execution) =
  execution.variables[assign.variable.ident] = assign.value.eval(execution)
method children(assign: VariableAssign): seq[ASTNode] =
  @[assign.variable.ASTNode, assign.value.ASTNode]
method replaceChild(assign: VariableAssign, child, toAdd: ExprNode): bool =
  if assign.variable.ExprNode == child:
    assign.variable = toAdd.Variable
    return true
  if assign.value == child:
    assign.value = toAdd
    return true
method removeChild(assign: VariableAssign, child: ExprNode) =
  if assign.variable.ExprNode == child:
    assign.variable = Variable(ident: "")
  if assign.value == child:
    assign.value = Empty()

type
  BinaryExpr = ref BinaryExprObj
  BinaryExprObj = object of ExprNode
    op: BinaryOp
    left: ExprNode
    right: ExprNode
  BinaryOp = enum
    add
    subtract
    multiply
    divide

astJson(BinaryExprObj, BinaryExpr)

proc displayText(op: BinaryOp): string =
  case op
  of add:
    "+"
  of subtract:
    "-"
  of multiply:
    "x"
  of divide:
    "/"

proc perform(op: BinaryOp, left, right: Value): Value =
  case op
  of add:
    left + right
  of subtract:
    left - right
  of multiply:
    left * right
  of divide:
    left div right

proc centerPos(binary: BinaryExpr): Vec =
  vec((binary.left.size.x - binary.right.size.x) / 2, 0)
proc leftPos(binary: BinaryExpr): Vec =
  binary.centerPos + vec(-binary.left.size.x / 2 - 18, 0)
proc rightPos(binary: BinaryExpr): Vec =
  binary.centerPos + vec(binary.right.size.x / 2 + 18, 0)

method size(binary: BinaryExpr): Vec =
  let
    sizeL = binary.left.size
    sizeR = binary.right.size
  vec(sizeL.x + sizeR.x + 42, max(sizeL.y, sizeR.y) + 10)
method menuSelf(binary: BinaryExpr, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      binary.bodyNode(binary.size, color.gray),
      BorderedTextNode(
        pos: binary.centerPos,
        text: binary.op.displayText,
      ),
      binary.left.menu(binary.leftPos),
      binary.right.menu(binary.rightPos),
    ],
  )
method eval(binary: BinaryExpr, execution: Execution): Value =
  let
    lval = binary.left.eval(execution)
    rval = binary.right.eval(execution)
  perform(binary.op, lval, rval)
method handleInput(binary: BinaryExpr, input: InputManager) =
  binary.dirty = true
  if input.isPressed(Input.keyA):
    binary.op = add
  elif input.isPressed(Input.keyS):
    binary.op = subtract
  elif input.isPressed(Input.keyM):
    binary.op = multiply
  elif input.isPressed(Input.keyD):
    binary.op = divide
  else:
    binary.dirty = false
method children(binary: BinaryExpr): seq[ASTNode] =
  @[binary.left.ASTNode, binary.right.ASTNode]
method replaceChild(binary: BinaryExpr, child, toAdd: ExprNode): bool =
  if binary.left == child:
    binary.left = toAdd
    return true
  elif binary.right == child:
    binary.right = toAdd
    return true
method removeChild(binary: BinaryExpr, child: ExprNode) =
  if binary.left == child:
    binary.left = Empty()
  elif binary.right == child:
    binary.right = Empty()

type
  Print = ref PrintObj
  PrintObj = object of StmtNode
    ast: ExprNode

astJson(PrintObj, Print)

method size(print: Print): Vec =
  print.ast.size + vec(95, 10)
method menuSelf(print: Print, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      print.bodyNode(print.size, color.darkGray),
      BorderedTextNode(
        pos: vec(50 - print.size.x / 2, 0),
        text: "PRINT",
      ),
      print.ast.menu(vec((print.size.x - print.ast.size.x) / 2 - 2, 0)),
    ],
  )
method execute(print: Print, execution: var Execution) =
  execution.output.add $print.ast.eval(execution)
method children(print: Print): seq[ASTNode] =
  @[print.ast.ASTNode]
method replaceChild(print: Print, child, toAdd: ExprNode): bool =
  if print.ast == child:
    print.ast = toAdd
    return true
method removeChild(print: Print, child: ExprNode) =
  if print.ast == child:
    print.ast = Empty()

type
  StmtList = ref StmtListObj
  StmtListObj = object of StmtNode
    statements: seq[StmtNode]

astJson(StmtListObj, StmtList)

const
  listBorder = 5.0
  listItemSpacing = 4.0
method size(list: StmtList): Vec =
  for statement in list.statements:
    result.x.max = statement.size.x
    result.y += statement.size.y
  result.x += listBorder
  result.y += listBorder
  result.y += listItemSpacing * (list.statements.len - 1).float
method menuSelf(list: StmtList, pos: Vec): Node =
  let size = list.size
  var
    stmtNodes = newSeq[Node]()
    curY = (-size.y + listBorder) / 2
  for statement in list.statements:
    let pos = vec(0.0, curY + statement.size.y / 2)
    stmtNodes.add statement.menu(pos)
    curY += statement.size.y + listItemSpacing
  result = list.bodyNode(list.size, color.darkGray, stmtNodes)
  result.pos = pos + size / 2
method execute(list: StmtList, execution: var Execution) =
  for statement in list.statements:
    statement.execute(execution)
method children(list: StmtList): seq[ASTNode] =
  result = @[]
  for statement in list.statements:
    result.add statement
method addNode(list: StmtList, toAdd: StmtNode): bool =
  list.statements.add toAdd
  true

proc output(statement: StmtNode): seq[string] =
  var execution = newExecution()
  statement.execute(execution)
  execution.output

type
  QLangPrototype = ref object of Program
    resources: ResourceManager
    ast: StmtNode
    cachedOutput: seq[string]
    menu: Node

proc newQLangPrototype(screenSize: Vec): QLangPrototype =
  new result
  result.title = "QLang (prototype)"
  result.resources = newResourceManager()
  let loadedJson = readJSONFile(savedCodeFile)
  if loadedJson.kind != jsError:
    echo "Loaded: ", loadedJson
    fromJSON(result.ast, loadedJson)
  else:
    result.ast = StmtList(
      statements: @[
        VariableAssign(
          variable: Variable(ident: "foo"),
          value: Literal(value: 5),
        ),
        Print(
          ast: BinaryExpr(
            op: multiply,
            left: Variable(ident: "foo"),
            right: Literal(value: 9),
          ),
        ),
        VariableAssign(
          variable: Variable(ident: "foo"),
          value: BinaryExpr(
            left: Variable(ident: "foo"),
            right: Literal(value: 2),
          ),
        ),
        Print(
          ast: BinaryExpr(
            op: multiply,
            left: Variable(ident: "foo"),
            right: Literal(value: 9),
          ),
        ),
      ],
    )
  selected = result.ast
  let offset = vec(50, 50)
  result.menu = result.ast.menu(offset)

  echo result.ast.toJSON.toPrettyString

proc outputNode(program: QLangPrototype): Node =
  stringListNode(@["Output:"] & program.cachedOutput, vec(900, 600))

proc findParentOf(ast: ASTNode, child: ASTNode): ASTNode =
  for node in ast.flattenedNodes:
    if child in node.children:
      return node

proc findAllParentsOf(ast: ASTNode, child: ASTNode): seq[ASTNode] =
  result = @[]
  var cur = child
  while cur != nil:
    result.add cur
    cur = ast.findParentOf(cur)

proc moveSelected(ast: ASTNode, dir: int) =
  if selected == nil or selected == ast:
    selected = ast
    return
  let parent = ast.findParentOf(selected)
  assert parent != nil, "Selected node should have parent in AST"

  let siblings = parent.children
  assert siblings.len > 0, "Parent of selected node should have at least one child"

  let
    index = siblings.find(selected)
    newIndex = index + dir
    outOfBounds = newIndex < 0 or newIndex >= siblings.len
  selected =
    if outOfBounds and dir > 0:
      siblings[siblings.len - 1]
    elif outOfBounds and dir < 0:
      siblings[0]
    else:
      siblings[newIndex]

proc moveUp(ast: ASTNode) =
  if selected == nil:
    selected = ast
    return

  let parent = ast.findParentOf(selected)
  if parent != nil:
    selected = parent

proc moveDown(ast: ASTNode) =
  if selected == nil:
    selected = ast
    return

  if selected.children.len > 0:
    selected = selected.children[0]

proc addNode(program: QLangPrototype, toAdd: ASTNode) =
  var addTo = selected
  while addTo != nil:
    if addTo.addNode(toAdd):
      selected = toAdd
      return
    let parent = program.ast.findParentOf(addTo)
    if addTo.replaceOnAdd:
      if parent.replaceChild(addTo, toAdd):
        selected = toAdd
        return
    addTo = parent

proc deleteSelected(program: QLangPrototype) =
  if selected == nil:
    return
  let parent = program.ast.findParentOf(selected)
  assert parent != nil, "Selected node should have parent in AST"
  let idx = parent.children.find(selected)
  assert idx != -1, "Selected node must be in children of parent"
  parent.removeChild(selected)
  let clampedIdx = idx.clamp(0, parent.children.len - 1)
  selected = parent.children[clampedIdx]

method update*(program: QLangPrototype, dt: float) =
  let prevSelected = selected
  if program.input.isPressed(Input.menu):
    program.shouldExit = true

  program.menu.update(program.input)

  if program.input.isPressed(Input.arrowRight):
    moveSelected(program.ast, 1)
  if program.input.isPressed(Input.arrowLeft):
    moveSelected(program.ast, -1)
  if program.input.isPressed(Input.arrowUp):
    moveUp(program.ast)
  if program.input.isPressed(Input.arrowDown):
    moveDown(program.ast)
  if program.input.isPressed(Input.f5):
    program.cachedOutput = nil
  if program.input.isHeld(Input.ctrl):
    if program.input.isPressed(Input.keyS):
      writeJSONFile(savedCodeFile, program.ast.toJSON, pretty=true)
      log info, "Saved to file ", savedCodeFile
    if program.input.isPressed(Input.delete):
      program.deleteSelected()
    if program.input.isPressed(Input.keyL):
      program.addNode(Literal(value: 0))
    if program.input.isPressed(Input.keyV):
      program.addNode(Variable(ident: ""))
    if program.input.isPressed(Input.keyP):
      program.addNode(Print(ast: Empty()))
    if program.input.isPressed(Input.keyB):
      program.addNode(BinaryExpr(
        op: add,
        left: Empty(),
        right: Empty(),
      ))
  if selected != nil:
    selected.handleInput(program.input)

  if program.cachedOutput == nil:
    program.cachedOutput = output(program.ast)

  if selected != prevSelected:
    for node in program.ast.findAllParentsOf(prevSelected):
      node.dirty = true
    for node in program.ast.findAllParentsOf(selected):
      node.dirty = true

method draw*(renderer: RendererPtr, program: QLangPrototype) =
  renderer.draw(program.menu, program.resources)
  renderer.draw(program.outputNode, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newQLangPrototype(screenSize), screenSize)
