from sdl2 import RendererPtr

import
  component/sprite,
  camera,
  color,
  drawing,
  entity,
  event,
  game_system,
  rect,
  resources,
  util,
  vec

type
  DecorationInfo = ref object
    filename: string
    size: Vec
    sprite: SpriteData
  Decoration = object
    info: DecorationInfo
    pos: Vec
  ScrollingBackground* = object
    decos: seq[Decoration]
    infos: seq[DecorationInfo]
    loaded: bool
    spawnDist: float
    spawnedHi: float
    spawnedLo: float

proc newScrollingBackground*(): ScrollingBackground =
  result = ScrollingBackground(
    decos: @[],
    infos: @[
      DecorationInfo(filename: "GrassTuft.png",
                     size: vec(12, 8)),
      DecorationInfo(filename: "GrassTuft2.png",
                     size: vec(28, 12)),
    ],
    spawnDist: 5.0,
  )

proc loadBackgroundAssets*(
    background: var ScrollingBackground,
    resources: ResourceManager,
    renderer: RendererPtr) =
  if not background.loaded:
    for info in background.infos.mitems:
      info.sprite = resources.loadSprite(info.filename, renderer)
    background.loaded = true

defineDrawSystem:
  priority = 100
  proc drawBackground*(background: ScrollingBackground, camera: Camera) =
    let
      bgColor = rgb(67, 167, 81)
      bgRect = rect(camera.screenSize / 2, camera.screenSize)
    renderer.fillRect bgRect, bgColor

    for deco in background.decos:
      let
        info = deco.info
        r = rect(deco.pos + vec(0.0, camera.offset.y), info.size)
      renderer.draw info.sprite, r

defineSystem:
  proc updateBackground*(background: var ScrollingBackground, camera: Camera) =
    proc spawnAt(yOffset: float, infos: seq[DecorationInfo]): Decoration =
      let
        spawnPos = vec(random(0.0, camera.screenSize.x), yOffset + camera.screenSize.y)
        info = random(infos)
      Decoration(info: info, pos: spawnPos)
    while background.spawnedLo > -camera.offset.y - camera.screenSize.y:
      background.decos.add spawnAt(background.spawnedLo, background.infos)
      background.spawnedLo -= background.spawnDist
    while background.spawnedHi < -camera.offset.y:
      background.decos.add spawnAt(background.spawnedHi, background.infos)
      background.spawnedHi += background.spawnDist

    var toRemove = newSeq[Decoration]()
    for deco in background.decos:
      if deco.pos.y + camera.offset.y < 0.0:
        toRemove.add deco
        background.spawnedLo.max = deco.pos.y - camera.screenSize.y
      if deco.pos.y + camera.offset.y > camera.screenSize.y:
        toRemove.add deco
        background.spawnedHi.min = deco.pos.y - camera.screenSize.y
    for deco in toRemove:
      background.decos.remove deco
