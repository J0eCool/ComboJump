import sdl2

import
  rect,
  vec

proc sdlRect*(r: rect.Rect): sdl2.Rect =
  rect((r.x - r.w/2).cint, (r.y - r.h/2).cint, r.w.cint, r.h.cint)

proc drawLine*(renderer: RendererPtr, p1, p2: Vec) =
  renderer.drawLine(p1.x.cint, p1.y.cint, p2.x.cint, p2.y.cint)

proc fillRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = r.sdlRect
  renderer.fillRect sdlRect

proc drawRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = r.sdlRect
  renderer.drawRect sdlRect
