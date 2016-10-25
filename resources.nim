import
  sdl2.ttf,
  tables

import
  component/text,
  entity

type ResourceManager* = object
  fonts: Table[string, FontPtr]

proc loadFont*(resources: var ResourceManager, fontName: string): FontPtr =
  if not resources.fonts.hasKey(fontName):
    const hardcodedFontSize = 24 # TODO: not this?
    let font = openFont(fontName, hardcodedFontSize)
    resources.fonts[fontName] = font
  return resources.fonts[fontName]

proc newResourceManager*(): ResourceManager =
  result.fonts = initTable[string, FontPtr](8)

proc loadResources*(entities: Entities, resources: var ResourceManager) =
  entities.forComponents e, [
    Text, text,
  ]:
    if text.font == nil:
      text.font = resources.loadFont text.fontName
