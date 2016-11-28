import
  sdl2

import
  component/sprite,
  camera,
  drawing,
  event,
  rect,
  resources,
  system,
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
    speed: float
    loaded: bool

proc newScrollingBackground*(speed: float): ScrollingBackground =
  result = ScrollingBackground(
    decos: @[],
    infos: @[
      DecorationInfo(filename: "GrassTuft.png",
                     size: vec(12, 8)),
      DecorationInfo(filename: "GrassTuft2.png",
                     size: vec(28, 12)),
    ],
    speed: speed,
  )

proc loadBackgroundAssets*(
    background: var ScrollingBackground,
    resources: var ResourceManager,
    renderer: RendererPtr) =
  if not background.loaded:
    for info in background.infos.mitems:
      info.sprite = resources.loadSprite(info.filename, renderer)
    background.loaded = true

    background.decos = @[
      Decoration(info: background.infos[0], pos: vec(20, 20)),
      Decoration(info: background.infos[1], pos: vec(120, 20)),
      Decoration(info: background.infos[1], pos: vec(20, 120)),
      Decoration(info: background.infos[0], pos: vec(120, 120)),
    ]

proc draw*(renderer: RendererPtr, background: ScrollingBackground, camera: Camera) =
  renderer.setDrawColor color(67, 167, 81, 255)
  renderer.fillRect rect.rect(camera.screenSize / 2, camera.screenSize)

  for deco in background.decos:
    let
      info = deco.info
      r = rect.rect(deco.pos, info.size)
    renderer.draw info.sprite, r

