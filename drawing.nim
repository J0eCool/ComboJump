import
  sdl2,
  sdl2.ttf,
  tables

import
  component/sprite,
  color,
  rect,
  util,
  vec

type RenderedText* = tuple[texture: TexturePtr, size: Vec]

proc sdlColor*(c: color.Color): sdl2.Color =
  color(c.r, c.g, c.b, c.a)

proc sdlRect*(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc drawLine*(renderer: RendererPtr, p1, p2: Vec) =
  renderer.drawLine(p1.x.cint, p1.y.cint, p2.x.cint, p2.y.cint)

proc fillRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = (r - r.size / 2).sdlRect
  renderer.fillRect sdlRect

proc fillRect*(renderer: RendererPtr, r: rect.Rect, color: color.Color) =
  renderer.setDrawColor color.sdlColor
  renderer.fillRect(r)

proc drawRect*(renderer: RendererPtr, r: rect.Rect) =
  var sdlRect = (r - r.size / 2).sdlRect
  renderer.drawRect sdlRect

proc renderText*(renderer: RendererPtr, text: string, font: FontPtr, color: color.Color): RenderedText =
  let
    surface = font.renderTextBlended(text, color.sdlColor)
    texture = renderer.createTexture surface
    size = if surface == nil: vec() else: vec(surface.w, surface.h)
  (texture, size)

proc draw*(renderer: RendererPtr, rendered: RenderedText, pos: Vec) =
    var
      dstrect = sdlRect(rect(pos, rendered.size) - rendered.size / 2)
      srcrect = dstrect
    srcrect.x = 0
    srcrect.y = 0
    renderer.copy(rendered.texture, addr srcrect, addr dstrect)

proc draw*(renderer: RendererPtr,
           sprite: SpriteData,
           rect: rect.Rect,
           flipX = false,
           angle = 0.0) =
  var
    dstrect = sdlRect(rect - rect.size / 2)
    srcrect = sdlRect(sprite.size)
    flip = if flipX: SDL_FLIP_HORIZONTAL else: SDL_FLIP_NONE
  renderer.copyEx(sprite.texture, addr srcrect, addr dstrect,
                  angle=angle, center=nil, flip=flip)

var textCache = initTable[string, RenderedText]()
proc drawCachedText*(renderer: RendererPtr,
                     text: string,
                     pos: Vec,
                     font: FontPtr,
                     color: color.Color = rgb(255, 255, 255),
                    ) =
  let textKey = text & "__color:" & $color
  if not textCache.hasKey(textKey):
    textCache[textKey] = renderer.renderText(text, font, color)
  renderer.draw(textCache[textKey], pos)

proc drawBorderedText*(renderer: RendererPtr,
                       text: string,
                       pos: Vec,
                       font: FontPtr,
                       color: color.Color = rgb(255, 255, 255),
                      ) =
  let
    black = rgb(0, 0, 0)
    borderWidth = 2
  for x in -1..1:
    for y in -1..1:
      if x != 0 or y != 0:
        renderer.drawCachedText(text, pos + vec(x, y) * borderWidth, font, black)
  renderer.drawCachedText(text, pos, font, color)

