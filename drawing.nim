import
  sdl2,
  sdl2.ttf

import
  rect,
  vec

type RenderedText* = tuple[texture: TexturePtr, size: Vec]

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

proc renderText*(renderer: RendererPtr, text: string, font: FontPtr, color: Color): RenderedText =
  let
    surface = font.renderTextBlended(text, color)
    texture = renderer.createTexture surface
    size = vec(surface.w, surface.h)
  (texture, size)

proc drawTexture*(renderer: RendererPtr, texture: TexturePtr, r: rect.Rect) =
  var
    dstrect = sdlRect(r)
    srcrect = dstrect
  srcrect.x = 0
  srcrect.y = 0
  renderer.copy(texture, addr srcrect, addr dstrect)

proc draw*(renderer: RendererPtr, rendered: RenderedText, pos: Vec) =
    renderer.drawTexture(rendered.texture, rect(pos, rendered.size))
