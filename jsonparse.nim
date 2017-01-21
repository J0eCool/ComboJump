import
  algorithm,
  parseutils,
  sequtils,
  strutils,
  tables,
  typetraits

import util

type
  JSONTokenKind = enum
    literal
    comma
    colon
    arrayStart
    arrayEnd
    objectStart
    objectEnd
    null
    error
  JSONToken = object
    case kind: JSONTokenKind
    of literal, error:
      value: string
    of comma, colon, arrayStart, arrayEnd, objectStart, objectEnd, null:
      discard

  JSONKind* = enum
    jsObject
    jsArray
    jsString
    jsNull
    jsError
  JSON* = object
    case kind*: JSONKind
    of jsObject:
      obj*: Table[string, JSON]
    of jsArray:
      arr*: seq[JSON]
    of jsString:
      str*: string
    of jsNull:
      discard
    of jsError:
      msg*: string

proc `$`(token: JSONToken): string =
  case token.kind:
  of literal:
    '"' & token.value & '"'
  of error:
    "<|" & token.value & "|>"
  else:
    $token.kind

proc tokenizeJSON(str: string): seq[JSONToken] =
  var
    curr = ""
    i = 0
    readingString = false
  result = @[]
  proc t(kind: JSONTokenKind): JSONToken =
    JSONToken(kind: kind)
  while i < str.len:
    let c = str[i]
    i += 1
    if readingString:
      if c != '"':
        curr &= c
      else:
        result.add JSONToken(kind: literal, value: curr)
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
        result.add JSONToken(kind: error, value: "Expected 'null', got '" & str[i-1..i+2] & "'")
        return
    else:
      result.add JSONToken(kind: error, value: "Unexpected character '" & c & "'")
      return

proc parseJSONTokensFrom(idx: var int, tokens: seq[JSONToken]): JSON =
  var t = tokens[idx]
  idx += 1
  case t.kind:
  of null:
    return JSON(kind: jsNull)
  of literal:
    return JSON(kind: jsString, str: t.value)
  of arrayStart:
    var arr: seq[JSON] = @[]
    while tokens[idx].kind != arrayEnd:
      arr.add parseJSONTokensFrom(idx, tokens)
      let k = tokens[idx].kind
      if k == comma:
        idx += 1
      elif k != arrayEnd:
        return JSON(kind: jsError,
                    msg: "Expected arrayEnd, got " & $k & " at token idx=" & $idx)
    idx += 1
    return JSON(kind: jsArray, arr: arr)
  of objectStart:
    var dict = initTable[string, JSON](8)
    while tokens[idx].kind != objectEnd:
      let key = tokens[idx]
      if key.kind != literal:
        return JSON(kind: jsError,
                    msg: "Expected object key to be a string, got " & $key.kind & " at token idx=" & $idx)
      let keyStr = key.value

      let sep = tokens[idx+1].kind
      if sep != colon:
        return JSON(kind: jsError,
                    msg: "Expected colon after object key, got " & $sep & " at token idx=" & $idx)
      idx += 2

      let value = parseJSONTokensFrom(idx, tokens)
      dict[keyStr] = value

      let next = tokens[idx].kind
      if next == comma:
        idx += 1
      elif next != objectEnd:
        return JSON(kind: jsError,
                    msg: "Expected objectEnd, got " & $next & " at token idx=" & $idx)
    idx += 1
    return JSON(kind: jsObject, obj: dict)
  else:
    return JSON(kind: jsError,
                msg: "Unexpected token, got " & $t.kind & " at token idx=" & $idx)
  
proc parseJSONTokens(tokens: seq[JSONToken]): JSON =
  var idx = 0
  parseJSONTokensFrom(idx, tokens)

proc deserializeJSON*(str: string): JSON =
  parseJSONTokens(tokenizeJSON(str))

iterator sortedPairs(dict: Table[string, JSON]): tuple[key: string, value: JSON] =
  var sortedKeys = newSeq[string]()
  for k in dict.keys:
    sortedKeys.add k
  sortedKeys.sort(
    proc(a, b: string): int =
      cmp[string](a, b)
  )
  for k in sortedKeys:
    yield (k, dict[k])

proc serializeJSON*(json: JSON, pretty=false, indents=0): string =
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
      result &= newline & indentation & tab & serializeJSON(x, pretty, indents+1)
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
          serializeJSON(v, pretty, indents+1)
      first = false
    result &= newline & indentation & "}"
  of jsError:
    result = "<|" & json.msg & "|>" & newline

proc `$`*(json: JSON): string =
  serializeJSON(json)

proc toPrettyString*(json: JSON): string =
  serializeJSON(json, pretty=true)

proc readJSONFile*(filename: string): JSON =
  try:
    deserializeJSON(readFile(filename).string)
  except:
    JSON(kind: jsError, msg: "File " & filename & " doesn't exist")

proc writeJSONFile*(filename: string, json: JSON, pretty = false) =
  writeFile(filename, json.serializeJSON(pretty))

proc fromJSON*[T](json: JSON): T
proc fromJSON*(x: var int, json: JSON) =
  assert json.kind == jsString
  x = parseInt(json.str)
proc fromJSON*(x: var bool, json: JSON) =
  assert json.kind == jsString
  case json.str
  of "true":
    x = true
  of "false":
    x = false
  else:
    assert false, "Invalid bool value " & json.str
proc fromJSON*(str: var string, json: JSON) =
  case json.kind
  of jsString:
    str = json.str
  of jsNull:
    str = nil
  else:
    assert false
proc fromJSON*[T](list: var seq[T], json: JSON) =
  assert json.kind == jsArray
  list = @[]
  for j in json.arr:
    list.add fromJSON[T](j)
proc fromJSON*[N, T](list: var array[N, T], json: JSON) =
  assert json.kind == jsArray
  for i in 0..<json.arr.len:
    list[i] = fromJSON[T](json.arr[i])
proc fromJSON*[T: enum](item: var T, json: JSON) =
  assert json.kind == jsString
  for e in T:
    if json.str == $e:
      item = e
      return
  assert false, "Invalid " & T.type.name & " value: " & json.str
proc fromJSON*[K, V](table: var Table[K, V], json: JSON) =
  assert json.kind == jsObject
  table = initTable[K, V]()
  for rawK, rawV in json.obj:
    var
      k: K
      v: V
    k.fromJSON(JSON(kind: jsString, str: rawK))
    v.fromJSON(rawV)
    table[k] = v
proc fromJSON*[T: object](obj: var T, json: JSON) =
  obj = T()
  for field, val in obj.fieldPairs:
    val.fromJSON(json.obj[field])
proc fromJSON*[T](json: JSON): T =
  var x: T
  x.fromJSON(json)
  return x

proc toJSON*(x: int): JSON =
  JSON(kind: jsString, str: $x)
proc toJSON*(x: bool): JSON =
  JSON(kind: jsString, str: $x)
proc toJSON*(str: string): JSON =
  if str != nil:
    JSON(kind: jsString, str: str)
  else:
    JSON(kind: jsNull)
proc toJSON*[T](list: seq[T]): JSON =
  var arr: seq[JSON] = @[]
  for item in list:
    arr.add item.toJSON
  JSON(kind: jsArray, arr: arr)
proc toJSON*[N, T](list: array[N, T]): JSON =
  toJSON(@list)
proc toJSON*[T: enum](item: T): JSON =
  JSON(kind: jsString, str: $item)
proc toJSON*[K, V](table: Table[K, V]): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for k, v in table:
    let
      rawK = k.toJSON()
      rawV = v.toJSON()
    assert rawK.kind == jsString
    result.obj[rawK.str] = rawV
proc toJSON*[T: object](obj: T): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for field, val in obj.fieldPairs:
    result.obj[field] = val.toJSON()
