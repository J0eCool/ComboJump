import
  sdl2,
  sdl2.image,
  sdl2.ttf,
  tables

import
  component/sprite,
  component/text,
  entity,
  rect

type ResourceManager* = object
  sprites: Table[string, SpriteData]
  fonts: Table[string, FontPtr]

proc loadSprite*(resources: var ResourceManager, textureName: string, renderer: RendererPtr): SpriteData =
  const textureFolder = "assets/textures/"
  if not resources.sprites.hasKey(textureName):
    echo "Loading texture \"", textureName, "\""
    let surface = load(textureFolder & textureName)
    if surface == nil:
      echo "  Unable to load texture at " & textureFolder, textureName
      return nil
    let
      texture = renderer.createTextureFromSurface(surface)
      size = rect.rect(0, 0, surface.w, surface.h)
    let sprite = SpriteData(texture: texture, size: size)
    resources.sprites[textureName] = sprite
  return resources.sprites[textureName]

proc loadFont*(resources: var ResourceManager, fontName: string): FontPtr =
  const fontFolder = "assets/fonts/"
  if not resources.fonts.hasKey(fontName):
    echo "Loading font \"", fontName, "\""
    const hardcodedFontSize = 24 # TODO: not this?
    let font = openFont(fontFolder & fontName, hardcodedFontSize)
    if font == nil:
      echo "  Unable to load font at " & fontFolder, fontName
      return nil
    resources.fonts[fontName] = font
  return resources.fonts[fontName]

proc newResourceManager*(): ResourceManager =
  result.sprites = initTable[string, SpriteData](64)
  result.fonts = initTable[string, FontPtr](8)

proc loadResources*(entities: Entities, resources: var ResourceManager, renderer: RendererPtr) =
  entities.forComponents e, [
    Text, text,
  ]:
    if text.fontName != nil and text.font == nil:
      text.font = resources.loadFont text.fontName
      if text.font == nil:
        text.fontName = nil

  entities.forComponents e, [
    Sprite, sprite,
  ]:
    if sprite.textureName != nil and sprite.sprite == nil:
      sprite.sprite = resources.loadSprite(sprite.textureName, renderer)
      if sprite.sprite == nil:
        sprite.textureName = nil
