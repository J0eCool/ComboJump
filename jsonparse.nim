import
  algorithm,
  macros,
  parseutils,
  sequtils,
  strutils,
  tables,
  typetraits

import util

type
  JsonTokenKind = enum
    literal
    comma
    colon
    arrayStart
    arrayEnd
    objectStart
    objectEnd
    null
    error
  JsonToken = object
    case kind: JsonTokenKind
    of literal, error:
      value: string
    of comma, colon, arrayStart, arrayEnd, objectStart, objectEnd, null:
      discard

  JsonKind* = enum
    jsObject
    jsArray
    jsString
    jsNull
    jsError
  Json* = object
    case kind*: JsonKind
    of jsObject:
      obj*: Table[string, Json]
    of jsArray:
      arr*: seq[Json]
    of jsString:
      str*: string
    of jsNull:
      discard
    of jsError:
      msg*: string

proc `$`(token: JsonToken): string =
  case token.kind:
  of literal:
    '"' & token.value & '"'
  of error:
    "<|" & token.value & "|>"
  else:
    $token.kind

proc tokenizeJson(str: string): seq[JsonToken] =
  var
    curr = ""
    i = 0
    readingString = false
  result = @[]
  proc t(kind: JsonTokenKind): JsonToken =
    JsonToken(kind: kind)
  while i < str.len:
    let c = str[i]
    i += 1
    if readingString:
      if c != '"':
        curr &= c
      else:
        result.add JsonToken(kind: literal, value: curr)
        curr = ""
        readingString = false
      continue

    if c.isSpaceAscii():
      continue

    case c
    of '{': result.add t(objectStart)
    of '}': result.add t(objectEnd)
    of '[': result.add t(arrayStart)
    of ']': result.add t(arrayEnd)
    of ',': result.add t(comma)
    of ':': result.add t(colon)
    of '"': readingString = true
    of 'n':
      if str[i..i+2] == "ull":
        result.add t(null)
        i += 3
      else:
        result.add JsonToken(kind: error, value: "Expected 'null', got '" & str[i-1..i+2] & "'")
        return
    else:
      result.add JsonToken(kind: error, value: "Unexpected character '" & c & "'")
      return

proc parseJsonTokensFrom(idx: var int, tokens: seq[JsonToken]): Json =
  var t = tokens[idx]
  idx += 1
  case t.kind:
  of null:
    return Json(kind: jsNull)
  of literal:
    return Json(kind: jsString, str: t.value)
  of arrayStart:
    var arr: seq[Json] = @[]
    while tokens[idx].kind != arrayEnd:
      arr.add parseJsonTokensFrom(idx, tokens)
      let k = tokens[idx].kind
      if k == comma:
        idx += 1
      elif k != arrayEnd:
        return Json(kind: jsError,
                    msg: "Expected arrayEnd, got " & $k & " at token idx=" & $idx)
    idx += 1
    return Json(kind: jsArray, arr: arr)
  of objectStart:
    var dict = initTable[string, Json](8)
    while tokens[idx].kind != objectEnd:
      let key = tokens[idx]
      if key.kind != literal:
        return Json(kind: jsError,
                    msg: "Expected object key to be a string, got " & $key.kind & " at token idx=" & $idx)
      let keyStr = key.value

      let sep = tokens[idx+1].kind
      if sep != colon:
        return Json(kind: jsError,
                    msg: "Expected colon after object key, got " & $sep & " at token idx=" & $idx)
      idx += 2

      let value = parseJsonTokensFrom(idx, tokens)
      dict[keyStr] = value

      let next = tokens[idx].kind
      if next == comma:
        idx += 1
      elif next != objectEnd:
        return Json(kind: jsError,
                    msg: "Expected objectEnd, got " & $next & " at token idx=" & $idx)
    idx += 1
    return Json(kind: jsObject, obj: dict)
  else:
    return Json(kind: jsError,
                msg: "Unexpected token, got " & $t.kind & " at token idx=" & $idx)
  
proc parseJsonTokens(tokens: seq[JsonToken]): Json =
  var idx = 0
  parseJsonTokensFrom(idx, tokens)

proc deserializeJson*(str: string): Json =
  parseJsonTokens(tokenizeJson(str))

iterator sortedPairs(dict: Table[string, Json]): tuple[key: string, value: Json] =
  var sortedKeys = newSeq[string]()
  for k in dict.keys:
    sortedKeys.add k
  sortedKeys.sort(
    proc(a, b: string): int =
      cmp[string](a, b)
  )
  for k in sortedKeys:
    yield (k, dict[k])

proc serializeJson*(json: Json, pretty=false, indents=0): string =
  let
    tab = if not pretty: "" else: "  "
    indentation = if not pretty: "" else: tab.repeat(indents)
    newline = if not pretty: "" else: "\n"
    space = if not pretty: "" else: " "
  case json.kind
  of jsNull:
    result = "null"
  of jsString:
    result = "\"" & json.str & "\""
  of jsArray:
    result = "["
    var first = true
    for x in json.arr:
      if not first:
        result &= ","
      result &= newline & indentation & tab & serializeJson(x, pretty, indents+1)
      first = false
    result &= newline & indentation & "]"
  of jsObject:
    result = "{"
    var first = true
    for k, v in json.obj.sortedPairs:
      if not first:
        result &= ","
      result &= newline & indentation & tab &
          "\"" & k & "\":" & space &
          serializeJson(v, pretty, indents+1)
      first = false
    result &= newline & indentation & "}"
  of jsError:
    result = "<|" & json.msg & "|>" & newline

proc `$`*(json: Json): string =
  serializeJson(json)

proc toPrettyString*(json: Json): string =
  serializeJson(json, pretty=true)

proc readJsonFile*(filename: string): Json =
  try:
    deserializeJson(readFile(filename).string)
  except:
    Json(kind: jsError, msg: "File " & filename & " doesn't exist")

proc writeJsonFile*(filename: string, json: Json, pretty = false) =
  writeFile(filename, json.serializeJson(pretty))

proc fromJson*[T](json: Json): T
proc fromJson*[T: int | uint8](x: var T, json: Json) =
  assert json.kind == jsString
  x = T(parseInt(json.str))
proc fromJson*(x: var float, json: Json) =
  assert json.kind == jsString
  x = parseFloat(json.str)
proc fromJson*(x: var bool, json: Json) =
  assert json.kind == jsString
  case json.str
  of "true":
    x = true
  of "false":
    x = false
  else:
    assert false, "Invalid bool value " & json.str
proc fromJson*(str: var string, json: Json) =
  case json.kind
  of jsString:
    str = json.str
  of jsNull:
    str = nil
  else:
    assert false
proc fromJson*[T](list: var seq[T], json: Json) =
  assert json.kind == jsArray
  list = @[]
  for j in json.arr:
    list.add fromJson[T](j)
proc fromJson*[N, T](list: var array[N, T], json: Json) =
  assert json.kind == jsArray
  for i in 0..<json.arr.len:
    list[i] = fromJson[T](json.arr[i])
proc fromJson*[T: enum](item: var T, json: Json) =
  assert json.kind == jsString
  for e in T:
    if json.str == $e:
      item = e
      return
  assert false, "Invalid " & T.type.name & " value: " & json.str
proc fromJson*[K, V](table: var Table[K, V], json: Json) =
  assert json.kind == jsObject
  table = initTable[K, V]()
  for rawK, rawV in json.obj:
    var
      k: K
      v: V
    k.fromJson(Json(kind: jsString, str: rawK))
    v.fromJson(rawV)
    table[k] = v
proc fromJson*[T: tuple](obj: var T, json: Json) =
  for field, val in obj.fieldPairs:
    val.fromJson(json.obj[field])
proc fromJson*[T](json: Json): T =
  var x: T
  x.fromJson(json)
  return x

proc toJson*(x: int | uint8): Json =
  Json(kind: jsString, str: $x)
proc toJson*(x: float): Json =
  Json(kind: jsString, str: $x)
proc toJson*(x: bool): Json =
  Json(kind: jsString, str: $x)
proc toJson*(str: string): Json =
  if str != nil:
    Json(kind: jsString, str: str)
  else:
    Json(kind: jsNull)
proc toJson*[T](list: seq[T]): Json =
  var arr: seq[Json] = @[]
  for item in list:
    arr.add item.toJson
  Json(kind: jsArray, arr: arr)
proc toJson*[N, T](list: array[N, T]): Json =
  toJson(@list)
proc toJson*[T: enum](item: T): Json =
  Json(kind: jsString, str: $item)
proc toJson*[K, V](table: Table[K, V]): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  for k, v in table:
    let
      rawK = k.toJson()
      rawV = v.toJson()
    assert rawK.kind == jsString
    result.obj[rawK.str] = rawV
proc toJson*[T: tuple](obj: T): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  for field, val in obj.fieldPairs:
    result.obj[field] = val.toJson()

macro autoObjectJsonProcs*(objType: untyped, blacklist: seq[string] = @[]): untyped =
  let
    importTableStmt = newTree(nnkImportStmt, ident("tables"))
    toJsonProc = newProc(postfix(ident("toJson"), "*"),
      params=[
        ident("Json"),
        newIdentDefs(ident("obj"), objType),
      ])
    resAssign = newAssignment(ident("result"),
      newTree(nnkObjConstr, ident("Json"),
        newColonExpr(ident("kind"), ident("jsObject")),
        newColonExpr(ident("obj"),
          newCall(newTree(nnkBracketExpr,
            ident("initTable"), ident("string"), ident("Json")
          ))
        ),
      )
    )
    toForStmt = newTree(nnkForStmt, ident("k"), ident("v"),
      newDotExpr(ident("obj"), ident("fieldPairs")),
      newTree(nnkWhenStmt,
        newTree(nnkElifBranch,
          newTree(nnkInfix, ident("notin"), ident("k"), blacklist),
          newAssignment(
            newTree(nnkBracketExpr,
              newDotExpr(ident("result"), ident("obj")),
              ident("k")
            ),
            newCall(ident("toJson"), ident("v"))
          )
        )
      )
    )
  toJsonProc.body.add resAssign
  toJsonProc.body.add toForStmt

  let
    fromJsonProc = newProc(postfix(ident("fromJson"), "*"),
      params=[
        newEmptyNode(),
        newIdentDefs(ident("obj"),
          newTree(nnkVarTy, objType)
        ),
        newIdentDefs(ident("json"), ident("Json")),
      ])
    fromForStmt = newTree(nnkForStmt, ident("k"), ident("v"),
      newDotExpr(ident("obj"), ident("fieldPairs")),
      newTree(nnkWhenStmt,
        newTree(nnkElifBranch,
          newTree(nnkInfix, ident("notin"), ident("k"), blacklist),
          newTree(nnkIfStmt,
            newTree(nnkElifBranch,
              newCall("hasKey",
                newDotExpr(ident("json"), ident("obj")),
                ident("k"),
              ),
              newCall("fromJson",
                ident("v"),
                newTree(nnkBracketExpr,
                  newDotExpr(ident("json"), ident("obj")),
                  ident("k")
                ),
              )
            )
          )
        )
      )
    )
  fromJsonProc.body.add fromForStmt

  newStmtList(
    importTableStmt,
    toJsonProc,
    fromJsonProc,
  )
