import
  sdl2,
  sdl2.ttf

import
  component/collider,
  component/sprite,
  component/text,
  component/transform,
  entity,
  rect,
  vec

type FontManager* = object
  font: FontPtr

proc loadFont(fontManager: var FontManager) =
  fontManager.font = openFont("nevis.ttf", 24)

proc newFontManager*(): FontManager =
  result.loadFont()

proc sdlRect(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr, fonts: FontManager) =
  forComponents(entities, e, [
    Transform, t,
    Sprite, s,
  ]):
    var rect = sdlRect(t.globalRect)
    renderer.setDrawColor(s.color)
    renderer.fillRect(rect)

  forComponents(entities, e, [
    Transform, t,
    Text, text,
  ]):
    if text.texture == nil:
      let surface = fonts.font.renderTextBlended(text.getText(), text.color)
      text.texture = renderer.createTexture surface
      t.size = vec(surface.w, surface.h)
    renderer.setDrawColor(text.color)
    var
      dstrect = t.globalRect.sdlRect
      srcrect = dstrect
    srcrect.x = 0
    srcrect.y = 0
    renderer.copy(text.texture, addr srcrect, addr dstrect)
