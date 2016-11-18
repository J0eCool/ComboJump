import
  algorithm,
  macros,
  parseutils,
  sequtils,
  strutils,
  tables

import
  entity,
  util

type
  JSONTokenKind = enum
    literal
    comma
    colon
    arrayStart
    arrayEnd
    objectStart
    objectEnd
    error
  JSONToken = object
    case kind: JSONTokenKind
    of literal, error:
      value: string
    of comma, colon, arrayStart, arrayEnd, objectStart, objectEnd:
      discard

  JSONKind = enum
    jsObject
    jsArray
    jsString
    jsNull
    jsError
  JSON = object
    case kind: JSONKind
    of jsObject:
      obj: Table[string, JSON]
    of jsArray:
      arr: seq[JSON]
    of jsString:
      str: string
    of jsNull:
      discard
    of jsError:
      msg: string

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

    case c
    of '{': result.add t(objectStart)
    of '}': result.add t(objectEnd)
    of '[': result.add t(arrayStart)
    of ']': result.add t(arrayEnd)
    of ',': result.add t(comma)
    of ':': result.add t(colon)
    of '"': readingString = true
    else:
      result.add JSONToken(kind: error, value: "Unexpected character '" & c & "'")
      return

proc parseJSONTokensFrom(idx: var int, tokens: seq[JSONToken]): JSON =
  var t = tokens[idx]
  idx += 1
  case t.kind:
  of literal:
    JSON(kind: jsString, str: t.value)
  of arrayStart:
    var arr: seq[JSON] = @[]
    while tokens[idx].kind != arrayEnd:
      arr.add parseJSONTokensFrom(idx, tokens)
      let k = tokens[idx].kind
      if k == comma:
        idx += 1
      elif k != arrayEnd:
        return JSON(kind: jsError, msg: "Unexpected token " & $k)
    JSON(kind: jsArray, arr: arr)
  else:
    JSON(kind: jsError, msg: "Unexpected token " & $t.kind)
  
proc parseJSONTokens(tokens: seq[JSONToken]): JSON =
  var idx = 0
  parseJSONTokensFrom(idx, tokens)

proc deserializeJSON(str: string): JSON =
  parseJSONTokens(tokenizeJSON(str))

proc serializeJSON(json: JSON): string =
  case json.kind
  of jsString:
    result = "\"" & json.str & "\""
  of jsObject:
    result = "{object}"
  of jsArray:
    result = "["
    var first = true
    for x in json.arr:
      if not first:
        result &= ","
      first = false
      result &= serializeJSON(x)
    result &= "]"
  of jsNull:
    result = "null"
  of jsError:
    result = "<|" & json.msg & "|>"

proc test(str: string) =
  echo "TEST: ", str
  echo "  Tokens: ", tokenizeJSON(str)
  echo "  Serialized: ", serializeJSON(deserializeJSON(str))

# test """"lol""""
# test """["a","b","c"]"""
test """["lol",["butts","lol"]]"""

# proc readJSONFile(filename: string): JSON =
#   parseStringToJSON(readFile(filename).string)

type Data = Table[string, int]
const sysFile = "systems.json"
proc readData(): Data =
  result = initTable[string, int](64)
  let
    inStr = readFile(sysFile).string
    lines = inStr.split("\n")
  for ln in lines:
    let parts = ln.split(":")
    if parts.len > 1:
      let
        name = parts[0]
        count = parts[1].parseInt
      result[name] = count

proc writeData(data: Data) =
  var outStr = ""
  for k, v in data.pairs:
    outStr &= k & ":" & $v & "\n"
  writeFile(sysFile, outStr)

proc getNextId(data: Data): int =
  var ids: seq[int] = @[]
  for d in data.values:
    ids.add d
  ids.sort(cmp)
  for x in ids:
    if x > result:
      return
    result += 1

macro defineSystem*(body: untyped): untyped =
  var data = readData()
  let key = $body[0].name
  if not data.hasKey(key):
    let nextId = getNextId(data)
    data[key] = nextId

  var ps = body[0].params
  ps[0] = ident("Events")
  ps.insert 1, newIdentDefs(ident("entities"), ident("Entities"))

  writeData(data)

  return body
