import dynlib, os, times
from sdl2 import delay

type
  SingleSymDylib[T] = object
    libName: string
    symName: string
    lastModTime: Time
    lib*: LibHandle
    frameDelay: int

proc log[T](dylib: SingleSymDylib[T], message: string) =
  echo message, " lib=", dylib.libName, " sym=", dylib.symName, " lastModified=", dylib.lastModTime

proc newSingleSymDylib*[T](libName, symName: string): SingleSymDylib[T] =
  SingleSymDylib[T](
    libName: libName,
    symName: symName,
    lastModTime: fromSeconds(0),
  )

proc doLibLoad[T](dylib: var SingleSymDylib[T]) =
  dylib.lib = loadLib(dylib.libName)
  while dylib.lib == nil:
    delay(100)
    dylib.lib = loadLib(dylib.libName)
  dylib.lastModTime = getLastModificationTime(dylib.libName)

# Offset each lib's load delay to stagger them and not have all the file operations at once
var frameDelayOffset = 0

const framesToDelay = 50

proc tryLoadLib*[T](dylib: var SingleSymDylib[T]) =
  if (dylib.lib != nil and dylib.frameDelay < framesToDelay) or not fileExists(dylib.libName):
    dylib.frameDelay += 1
    return

  dylib.frameDelay -= framesToDelay

  if dylib.lib == nil:
    dylib.log "First load!"
    dylib.doLibLoad()
    dylib.frameDelay = frameDelayOffset
    frameDelayOffset += 1
    return

  if dylib.lastModTime != getLastModificationTime(dylib.libName):
    dylib.log "Reloading!"
    dylib.lib.unloadLib()
    dylib.doLibLoad()

proc getSym*[T](dylib: SingleSymDylib[T]): T =
  # dylib.log "getting sym"
  result = cast[T](dylib.lib.symAddr(dylib.symName))
  if result == nil or dylib.lib == nil:
    dylib.log "Warning, nil!"
