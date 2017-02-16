import
  component/collider,
  entity,
  event,
  game_system,
  stages

type
  ExitZone* = ref object of Component
    stageEnd*: bool

defineComponent(ExitZone)

defineSystem:
  components = [ExitZone, Collider]
  proc updateExitZones*(stageData: var StageData) =
    if collider.collisions.len > 0:
      stageData.transitionTo = if exitZone.stageEnd: nextStage else: inMap
      if exitZone.stageEnd:
        stageData.didCompleteStage = true
