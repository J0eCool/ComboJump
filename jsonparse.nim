import
  algorithm,
  parseutils,
  sequtils,
  strutils,
  tables

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
    error
  JSONToken = object
    case kind: JSONTokenKind
    of literal, error:
      value: string
    of comma, colon, arrayStart, arrayEnd, objectStart, objectEnd:
      discard

  JSONKind* = enum
    jsObject
    jsArray
    jsString
    jsNull
    jsError
  JSON* = object
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
  const
    newlineStr = "\n"
    cr = newlineStr[0]
    lf = newlineStr[newlineStr.len-1]
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
    of ' ', cr, lf: discard
    else:
      result.add JSONToken(kind: error, value: "Unexpected character '" & c & "'")
      return

proc parseJSONTokensFrom(idx: var int, tokens: seq[JSONToken]): JSON =
  var t = tokens[idx]
  idx += 1
  case t.kind:
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

proc serializeJSON*(json: JSON): string =
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
      result &= serializeJSON(x)
      first = false
    result &= "]"
  of jsObject:
    result = "{"
    var first = true
    for k, v in json.obj:
      if not first:
        result &= ","
      result &= "\"" & k & "\":" & serializeJSON(v)
      first = false
    result &= "}"
  of jsError:
    result = "<|" & json.msg & "|>"

proc `$`*(json: JSON): string =
  serializeJSON(json)

proc readJSONFile*(filename: string): JSON =
  deserializeJSON(readFile(filename).string)

when isMainModule:
  proc test(str: string) =
    echo "TEST: ", str
    echo "  Tokens: ", tokenizeJSON(str)
    echo "  Serialized: ", deserializeJSON(str)
    echo "  Roundtrip : ", deserializeJSON(serializeJSON(deserializeJSON(str)))

  test """"lol""""
  test """["a", "b", "c"]"""
  test """["lol", ["butts", "lol"]]"""
  test """{"x": "12", "y": "9"}"""
  test """[
    { "x":"12"
    , "y" : "9"
    },
    "3",
    [ {"x": "3"}
    ],
    { "list": ["a", "b", "c"]
    , "obj":
      { "name": "Jerry"
      , "tags": ["player", "tall"]
      , "height": "6'2"
      }
    }
    ]"""
