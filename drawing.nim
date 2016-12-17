import
  sdl2,
  sdl2.ttf

import
  component/sprite,
  rect,
  util,
  vec

type RenderedText* = tuple[texture: TexturePtr, size: Vec]

proc sdlRect*(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc drawLine*(renderer: RendererPtr, p1, p2: Vec) =
  renderer.drawLine(p1.x.cint, p1.y.cint, p2.x.cint, p2.y.cint)

proc fillRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = (r - r.size / 2).sdlRect
  renderer.fillRect sdlRect

proc fillRect*(renderer: RendererPtr, r: rect.Rect, color: Color) =
  renderer.setDrawColor color
  renderer.fillRect(r)

proc drawRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = (r - r.size / 2).sdlRect
  renderer.drawRect sdlRect

proc renderText*(renderer: RendererPtr, text: string, font: FontPtr, color: Color): RenderedText =
  let
    surface = font.renderTextBlended(text, color)
    texture = renderer.createTexture surface
    size = vec(surface.w, surface.h)
  (texture, size)

proc draw*(renderer: RendererPtr, rendered: RenderedText, pos: Vec) =
    var
      dstrect = sdlRect(rect(pos, rendered.size) - rendered.size / 2)
      srcrect = dstrect
    srcrect.x = 0
    srcrect.y = 0
    renderer.copy(rendered.texture, addr srcrect, addr dstrect)

proc draw*(renderer: RendererPtr, sprite: SpriteData, rect: rect.Rect, flipX = false) =
  var
    dstrect = sdlRect(rect - rect.size / 2)
    srcrect = sdlRect(sprite.size)
    flip = if flipX: SDL_FLIP_HORIZONTAL else: SDL_FLIP_NONE
  renderer.copyEx(sprite.texture, addr srcrect, addr dstrect, angle=0.0, center=nil, flip=flip)
