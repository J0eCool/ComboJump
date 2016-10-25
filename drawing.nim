import
  sdl2,
  sdl2.ttf

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

proc drawText*(renderer: RendererPtr, text: string, pos: Vec, font: FontPtr, color: Color) =
  let
    surface = font.renderTextBlended(text, color)
    texture = renderer.createTexture surface
    size = vec(surface.w, surface.h)
  var
    dstrect = sdlRect(rect(pos, size))
    srcrect = dstrect
  srcrect.x = 0
  srcrect.y = 0
  renderer.copy(texture, addr srcrect, addr dstrect)

