import os, times

import
  entity,
  event,
  game_system,
  jsonparse

# ProjectConfig holds project-specific configurations. They get live-reloaded
# at run time (TODO: in dev builds only). These are values that should always
# exist, but may be tunable on a per-game basis.

type
  ProjectConfig* = object
    filename: string
    lastModTime: Time
    nextCheckTime: float

    gravity*: float

autoObjectJsonProcs(ProjectConfig, @[
  "filename",
  "lastModTime",
  "nextCheckTime",
])

proc reload(config: var ProjectConfig) =
  if not fileExists(config.filename):
    return
  let lastMod = getLastModificationTime(config.filename)
  if lastMod != config.lastModTime:
    let json = readJsonFile(config.filename)
    fromJson(config, json)
    config.lastModTime = lastMod

proc newProjectConfig*(filename: string): ProjectConfig =
  result = ProjectConfig(
    filename: "assets/configs/" & filename & ".config",
    gravity: 2100.0,
  )
  result.reload()

defineSystem:
  rebuild = true
  proc updateProjectConfig*(dt: float, config: var ProjectConfig) =
    config.nextCheckTime -= dt
    if config.nextCheckTime <= 0.0:
      config.reload()
      config.nextCheckTime = 1.0
