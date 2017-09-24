import
  os,
  sdl2,
  sdl2.image,
  sdl2.ttf,
  tables,
  times

import
  component/sprite,
  component/text,
  entity,
  logging,
  rect,
  util

type
  CachedResource*[T] = object
    item: T
    filename: string
    checkOffset: float
    nextCheckTime: float
    lastModified: Time

const offsetRange = 1.0
proc newCachedResource*[T](filename: string): CachedResource[T] =
  CachedResource[T](
    filename: filename,
    checkOffset: random(0.0, offsetRange),
  )

proc shouldUpdateCache*[T](cache: var CachedResource[T]): bool =
  let cur = epochTime()
  if cur < cache.nextCheckTime:
    return false

  cache.nextCheckTime = cur.int.float + cache.checkOffset + offsetRange
  let modified = getLastModificationTime(cache.filename)
  result = cache.lastModified != modified
  cache.lastModified = modified

type
  ResourceManager* = ref object
    sprites: Table[string, CachedResource[SpriteData]]
    fonts: Table[string, FontPtr]

const textureFolder = "assets/textures/"
proc doSpriteLoad(filename: string, renderer: RendererPtr): SpriteData =
  let surface = load(filename)
  if surface == nil:
    log error, "Unable to load texture at " & filename
    return nil
  let
    texture = renderer.createTextureFromSurface(surface)
    size = rect.rect(0, 0, surface.w, surface.h)
  SpriteData(
    texture: texture,
    size: size,
  )

proc updatedSpriteCache(cache: var CachedResource[SpriteData],
                        renderer: RendererPtr
                       ): SpriteData =
  if shouldUpdateCache(cache):
    log info, "Loading texture \"", cache.filename, "\""
    cache.item = doSpriteLoad(cache.filename, renderer)
  cache.item

proc loadSprite*(resources: ResourceManager, textureName: string, renderer: RendererPtr): SpriteData =
  if textureName == nil:
    return nil
    
  if not resources.sprites.hasKey(textureName):
    resources.sprites[textureName] = newCachedResource[SpriteData](textureFolder & textureName)

  return updatedSpriteCache(resources.sprites[textureName], renderer)

proc loadFont*(resources: ResourceManager,
               fontName: string,
               fontSize = 24,
              ): FontPtr =
  const fontFolder = "assets/fonts/"
  let cachedName = fontName & "__" & $fontSize & "pt"
  if not resources.fonts.hasKey(cachedName):
    log info, "Loading font \"", cachedName, "\""
    let font = openFont(fontFolder & fontName, fontSize.cint)
    if font == nil:
      log error, "Unable to load font at " & fontFolder, fontName
    resources.fonts[cachedName] = font
  return resources.fonts[cachedName]

proc newResourceManager*(): ResourceManager =
  ResourceManager(
    sprites: initTable[string, CachedResource[SpriteData]](64),
    fonts: initTable[string, FontPtr](8),
  )

proc loadResources*(entities: Entities, resources: ResourceManager, renderer: RendererPtr) =
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
