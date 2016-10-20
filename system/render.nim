import
  sdl2,
  sdl2.ttf,
  tables

import
  component/collider,
  component/sprite,
  component/text,
  component/transform,
  camera,
  entity,
  rect,
  vec

type ResourceManager* = object
  fonts: Table[string, FontPtr]

proc loadFont(resources: var ResourceManager, fontName: string): FontPtr =
  if not resources.fonts.hasKey(fontName):
    const hardcodedFontSize = 24 # TODO: not this?
    let font = openFont(fontName, hardcodedFontSize)
    resources.fonts[fontName] = font
  return resources.fonts[fontName]

proc newResourceManager*(): ResourceManager =
  result.fonts = initTable[string, FontPtr](8)

proc sdlRect(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc loadResources*(entities: Entities, resources: var ResourceManager) =
  entities.forComponents e, [
    Text, text,
  ]:
    if text.font == nil:
      text.font = resources.loadFont text.fontName

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr, camera: Camera) =
  entities.forComponents e, [
    Transform, t,
    Sprite, s,
  ]:
    var rect = sdlRect(t.globalRect + camera.offset)
    renderer.setDrawColor(s.color)
    renderer.fillRect(rect)

  entities.forComponents e, [
    Transform, t,
    Text, text,
  ]:
    if text.texture == nil:
      let surface = text.font.renderTextBlended(text.getText(), text.color)
      text.texture = renderer.createTexture surface
      t.size = vec(surface.w, surface.h)
    renderer.setDrawColor(text.color)
    var
      dstrect = t.globalRect.sdlRect
      srcrect = dstrect
    srcrect.x = 0
    srcrect.y = 0
    renderer.copy(text.texture, addr srcrect, addr dstrect)
