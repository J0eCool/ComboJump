import
  strutils,
  times

type LogLevel* = enum
  error
  warning
  info
  debug

const
  logThreshold = warning
  showDate = false
  dateFormat = (if showDate: "yyyy-MM-dd " else: "") & "HH:mm:ss'.'"

proc currentTimeString(): string =
  let localTime = getLocalTime(getTime())
  var millisecondStr = $((epochTime() * 1000).int mod 1000)
  while millisecondStr.len < 3:
    millisecondStr = "0" & millisecondStr
  localTime.format(dateFormat) & millisecondStr

proc log*(category: string, level: LogLevel, message: varargs[string, `$`]) =
  if level > logThreshold:
    return
  var str = currentTimeString() & " - "
  if category != "":
    str &= category & " - "
  str &= ($level).toUpper & ": "
  for x in message:
    str &= x
  echo str

proc log*(level: LogLevel, message: varargs[string, `$`]) =
  log("", level, message)
