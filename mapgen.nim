import
  sdl2

import
  program,
  vec

type MapGen* = ref object of Program
  p1: Vec
  p2: Vec
  t: float

proc newMapGen(): MapGen =
  new result
  result.initProgram()

method draw*(renderer: RendererPtr, map: MapGen) =
  renderer.setDrawColor(32, 32, 32)
  renderer.drawLine(map.p1.x.cint, map.p1.y.cint, map.p2.x.cint, map.p2.y.cint)

method update*(map: MapGen, dt: float) =
  map.t += dt
  map.p1 = unitVec(map.t * 1.2341) * 200 + vec(400, 200)
  map.p2 = unitVec(map.t * 2.1524) * 100 + vec(600, 700)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newMapGen(), screenSize)
