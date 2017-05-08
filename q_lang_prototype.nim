import
  hashes,
  sdl2,
  sequtils,
  tables

import
  system/[
    render,
  ],
  camera,
  color,
  entity,
  event,
  input,
  menu,
  option,
  program,
  rect,
  resources,
  stack,
  util,
  vec

proc bordered(node: Node, borderWidth = 1.0): Node =
  SpriteNode(
    size: node.size + vec(2 * borderWidth),
    color: color.black,
    children: @[node],
  )

type
  ASTNode = ref object of RootObj
  Variable = ref object of ASTNode
    name: string
  Value = int # TODO: non-int values
  VariableValues = Table[string, Value]
  Execution = object
    output: seq[string]
    variables: VariableValues # TODO: Stack of scopes

method size(node: ASTNode): Vec {.base.} =
  vec()
method menu(node: ASTNode, pos: Vec): Node {.base.} =
  Node()
method execute(node: ASTNode, execution: var Execution): Value {.base.} =
  0

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
  Empty = ref object of ASTNode

method size(empty: Empty): Vec =
  vec(24)
method menu(empty: Empty, pos: Vec): Node =
  result = bordered(SpriteNode(
    size: empty.size,
    color: color.lightGray,
  ))
  result.pos = pos

type
  Literal = ref object of ASTNode
    value: int

method size(literal: Literal): Vec =
  vec(36)
method menu(literal: Literal, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      bordered(SpriteNode(
        size: literal.size,
        color: color.lightGray,
      )),
      BorderedTextNode(
        text: $literal.value,
      ),
    ],
  )
method execute(literal: Literal, execution: var Execution): Value =
  literal.value

type VariableAssign = ref object of ASTNode
  variable: Variable
  value: ASTNode

method size(variable: Variable): Vec =
  vec(64, 36)
method menu(variable: Variable, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      bordered(SpriteNode(
        size: variable.size,
        color: color.lightGray,
      )),
      BorderedTextNode(
        text: variable.name,
      ),
    ],
  )
method execute(variable: Variable, execution: var Execution): Value =
  execution.getValue(variable.name)

method size(assign: VariableAssign): Vec =
  assign.value.size + vec(110, 6)
method menu(assign: VariableAssign, pos: Vec): Node =
  # TODO: reuse infix logic from binary exprs
  Node(
    pos: pos,
    children: @[
      bordered(SpriteNode(
        size: assign.size,
        color: color.gray,
      )),
      assign.variable.menu(vec((assign.variable.size.x - assign.size.x) / 2 + 2, 0)),
      BorderedTextNode(
        pos: vec(0, 0),
        text: ":=",
      ),
      assign.value.menu(vec((assign.size.x - assign.value.size.x) / 2 - 2, 0)),
    ],
  )
method execute(assign: VariableAssign, execution: var Execution): Value =
  execution.variables[assign.variable.name] = assign.value.execute(execution)

type
  BinaryExpr = ref object of ASTNode
    op: BinaryOp
    left: ASTNode
    right: ASTNode
  BinaryOp = enum
    add
    subtract
    multiply
    divide

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

proc perform(op: BinaryOp, left, right: int): int =
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
method menu(binary: BinaryExpr, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      bordered(SpriteNode(
        size: binary.size,
        color: color.gray,
      )),
      BorderedTextNode(
        pos: binary.centerPos,
        text: binary.op.displayText,
      ),
      binary.left.menu(binary.leftPos),
      binary.right.menu(binary.rightPos),
    ],
  )
method execute(binary: BinaryExpr, execution: var Execution): Value =
  let
    lval = binary.left.execute(execution)
    rval = binary.right.execute(execution)
  perform(binary.op, lval, rval)

type
  Print = ref object of ASTNode
    ast: ASTNode

method size(print: Print): Vec =
  print.ast.size + vec(95, 10)
method menu(print: Print, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      bordered(SpriteNode(
        size: print.size,
        color: color.darkGray,
      )),
      BorderedTextNode(
        pos: vec(50 - print.size.x / 2, 0),
        text: "PRINT",
      ),
      print.ast.menu(vec((print.size.x - print.ast.size.x) / 2 - 2, 0)),
    ],
  )
method execute(print: Print, execution: var Execution): Value =
  execution.output.add $print.ast.execute(execution)
  0

type StmtList = ref object of ASTNode
  statements: seq[ASTNode]

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
method menu(list: StmtList, pos: Vec): Node =
  let size = list.size
  var
    stmtNodes = newSeq[Node]()
    curY = (-size.y + listBorder) / 2
  for statement in list.statements:
    let pos = vec(0.0, curY + statement.size.y / 2)
    stmtNodes.add statement.menu(pos)
    curY += statement.size.y + listItemSpacing
  result = bordered(SpriteNode(
    size: list.size,
    color: darkGray,
    children: stmtNodes,
  ))
  result.pos = pos + size / 2
method execute(list: StmtList, execution: var Execution): Value =
  for statement in list.statements:
    discard statement.execute(execution)
  0

proc output(ast: ASTNode): seq[string] =
  var execution = newExecution()
  discard ast.execute(execution)
  execution.output

type
  QLangPrototype = ref object of Program
    resources: ResourceManager
    ast: ASTNode
    cachedOutput: seq[string]

proc newQLangPrototype(screenSize: Vec): QLangPrototype =
  new result
  result.title = "QLang (prototype)"
  result.resources = newResourceManager()
  result.ast = StmtList(
    statements: @[
      VariableAssign(
        variable: Variable(name: "foo"),
        value: Literal(value: 5),
      ),
      Print(
        ast: BinaryExpr(
          op: multiply,
          left: Variable(name: "foo"),
          right: Literal(value: 9),
        ),
      ),
      VariableAssign(
        variable: Variable(name: "foo"),
        value: BinaryExpr(
          left: Variable(name: "foo"),
          right: Literal(value: 2),
        ),
      ),
      Print(
        ast: BinaryExpr(
          op: multiply,
          left: Variable(name: "foo"),
          right: Literal(value: 9),
        ),
      ),
    ],
  )

proc outputNode(program: QLangPrototype): Node =
  stringListNode(@["Output:"] & program.cachedOutput, vec(900, 600))

proc menu(program: QLangPrototype): Node =
  let offset = vec(50, 50)
  menu(program.ast, offset)

method update*(program: QLangPrototype, dt: float) =
  if program.cachedOutput == nil:
    program.cachedOutput = output(program.ast)
  if program.input.isPressed(Input.menu):
    program.shouldExit = true

method draw*(renderer: RendererPtr, program: QLangPrototype) =
  renderer.draw(program.menu, program.resources)
  renderer.draw(program.outputNode, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newQLangPrototype(screenSize), screenSize)
