import dynlib, os, times
from sdl2 import delay

type
  SingleSymDylib[T] = object
    libName: string
    symName: string
    lastModTime: Time
    lib: LibHandle
    frameDelay: int

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

proc tryLoadLib*[T](dylib: var SingleSymDylib[T]) =
  if dylib.lib != nil and dylib.frameDelay < 50:
    dylib.frameDelay += 1
    return
  dylib.frameDelay = 0

  while not fileExists(dylib.libName):
    delay(100)
  if dylib.lib == nil:
    dylib.doLibLoad()
    return

  let newModTime = getLastModificationTime(dylib.libName)
  if dylib.lastModTime != newModTime:
    dylib.lib.unloadLib()
    dylib.lastModTime = newModTime
    dylib.doLibLoad()

proc getSym*[T](dylib: SingleSymDylib[T]): T =
  cast[T](dylib.lib.symAddr(dylib.symName))
