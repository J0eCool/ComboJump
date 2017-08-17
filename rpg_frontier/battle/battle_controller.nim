import sequtils

import
  rpg_frontier/[
    enemy,
    level,
    player_stats,
    potion,
    skill,
    skill_kind,
    transition,
  ],
  rpg_frontier/battle/[
    battle_entity,
    battle_model,
  ],
  color,
  menu,
  util,
  vec

type
  BattleController* = ref object of Controller
    floatingTexts*: seq[FloatingText]
    vfxs*: seq[Vfx]
    eventQueue*: seq[BattleEvent]
    asyncQueue*: seq[BattleEvent]
    bufferClose*: bool
  FloatingText* = object
    text*: string
    startPos*: Vec
    t: float
  BattleEvent = object
    duration: float
    update: EventUpdate
    t: float
  EventUpdate = proc(t: float)
  Vfx = object
    sprite*: string
    pos*: Vec
    scale*: float
    update: VfxUpdate
    duration: float
    t: float
  VfxUpdate = proc(vfx: var Vfx, t: float)

const
  textFloatHeight = 160.0
  textFloatTime = 1.25

proc percent(event: BattleEvent): float =
  if event.duration == 0.0:
    0.0
  else:
    clamp(event.t / event.duration, 0, 1)

proc percent(vfx: Vfx): float =
  if vfx.duration == 0.0:
    0.0
  else:
    clamp(vfx.t / vfx.duration, 0, 1)

proc newBattleController*(): BattleController =
  BattleController(
    name: "Battle",
    floatingTexts: @[],
    vfxs: @[],
    eventQueue: @[],
    asyncQueue: @[],
  )

proc processAttackDamage(controller: BattleController, damage: int, target: BattleEntity) =
  target.takeDamage(damage)
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: target.pos + randomVec(30.0),
  )

proc queueEvent(controller: BattleController, duration: float, update: EventUpdate) =
  controller.eventQueue.add BattleEvent(
    duration: duration,
    update: update,
  )
proc queueEvent(controller: BattleController, update: EventUpdate) =
  controller.queueEvent(0.0, update)
proc wait(controller: BattleController, duration: float) =
  controller.queueEvent(duration, (proc(t: float) = discard))

proc queueAsync(controller: BattleController, duration: float, update: EventUpdate) =
  controller.asyncQueue.add BattleEvent(
    duration: duration,
    update: update,
  )

proc advanceStage(battle: BattleData, controller: BattleController) =
  if battle.curStageIndex + 1 >= battle.stages.len:
    controller.bufferClose = true
  else:
    battle.curStageIndex += 1
    battle.spawnCurrentStage()

proc killEnemy(battle: BattleData, controller: BattleController, target: BattleEntity) =
  let xpGained = 1
  controller.floatingTexts.add FloatingText(
    text: "+" & $xpGained & "xp",
    startPos: target.pos + randomVec(5.0),
  )
  battle.stats.addXp(xpGained)
  let dx = random(300.0, 700.0)
  controller.queueEvent(0.8) do (pct: float):
    target.offset = vec(dx * pct, -2200.0 * pct * (0.25 - pct))
  controller.wait(0.1)
  controller.queueEvent do (pct: float):
    battle.enemies.mustRemove(target)
    battle.turnQueue = battle.turnQueue.filterIt(it.entity != target)
    if battle.enemies.len == 0:
      battle.advanceStage(controller)
  controller.wait(0.3)

proc killPlayer(battle: BattleData, controller: BattleController) =
  controller.bufferClose = true

proc updateMaybeKill(battle: BattleData, controller: BattleController, target: BattleEntity) =
  if target.health > 0:
    return

  if target == battle.player:
    battle.killPlayer(controller)
  else:
    battle.killEnemy(controller, target)

proc noAnimationPlaying*(controller: BattleController): bool =
  controller.eventQueue.len == 0

proc isClickReady*(battle: BattleData, controller: BattleController): bool =
  controller.noAnimationPlaying and battle.activeEntity == battle.player

proc startAttack*(battle: BattleData, controller: BattleController,
                 skill: SkillInfo, attacker, target: BattleEntity) =
  let
    damage = skill.damageFor(attacker)
    targets = skill.toTargets(battle.enemies, target)
  controller.queueEvent(0.1) do (t: float):
    battle.updateAttackAnimation(t)
  controller.queueEvent do (t: float):
    let basePos = target.pos - vec(100)
    controller.vfxs.add Vfx(
      pos: basePos,
      sprite: "Slash.png",
      scale: 4,
      duration: 0.2,
      update: (proc(vfx: var Vfx, t: float) =
        vfx.pos = basePos + t * vec(200)
      ),
    )
  controller.wait(0.1)
  controller.queueEvent do (t: float):
    for enemy in targets:
      controller.processAttackDamage(damage, enemy)
    controller.queueAsync(0.175) do (t: float):
      battle.updateAttackAnimation(1.0 - t)
  controller.queueEvent do (t: float):
    for enemy in targets:
      battle.updateMaybeKill(controller, enemy)
  controller.wait(0.25)
  controller.queueEvent do (t: float):
    battle.endTurn()

proc tryUseAttack*(battle: BattleData, controller: BattleController, entity: BattleEntity) =
  let skill = battle.selectedSkill
  assert skill != nil
  assert entity != nil
  if battle.canAfford(skill) and
     battle.isClickReady(controller):
    battle.player.mana -= skill.manaCost
    battle.player.focus -= skill.focusCost
    battle.startAttack(controller, skill, battle.player, entity)

proc canUse*(potion: Potion): bool =
  potion.charges > 0 and potion.cooldown == 0

proc tryUsePotion*(battle: BattleData, controller: BattleController, potion: ptr Potion) =
  if not potion[].canUse():
    return
  potion.charges -= 1

  let info = potion.info
  case info.kind
  of healthPotion:
    battle.player.health += info.effect
  of manaPotion:
    battle.player.mana += info.effect

proc pos*(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

proc clampResources(entity: BattleEntity) =
  entity.health = entity.health.clamp(0, entity.maxHealth)
  entity.mana = entity.mana.clamp(0, entity.maxMana)
  entity.focus = entity.focus.clamp(0, entity.maxFocus)
proc clampResources(battle: BattleData) =
  battle.player.clampResources()
  for enemy in battle.enemies.mitems:
    enemy.clampResources()

proc updateFloatingText(controller: BattleController, dt: float) =
  var newFloaties: seq[FloatingText] = @[]
  for text in controller.floatingTexts.mitems:
    text.t += dt
    if text.t <= textFloatTime:
      newFloaties.add text
  controller.floatingTexts = newFloaties

proc updateVfx(controller: BattleController, dt: float) =
  var newVfxs: seq[Vfx] = @[]
  for vfx in controller.vfxs.mitems:
    vfx.t += dt
    vfx.update(vfx, vfx.percent)
    if vfx.t <= vfx.duration:
      newVfxs.add vfx
  controller.vfxs = newVfxs

proc updateEventQueue(controller: BattleController, dt: float) =
  if controller.eventQueue.len > 0:
    controller.eventQueue[0].t += dt
    let cur = controller.eventQueue[0]
    if cur.t > cur.duration:
      controller.eventQueue.delete(0)
    cur.update(cur.percent)

proc updateAsyncQueue(controller: BattleController, dt: float) =
  var i = controller.asyncQueue.len - 1
  while i >= 0:
    controller.asyncQueue[i].t += dt
    let cur = controller.asyncQueue[i]
    cur.update(cur.percent)
    if cur.t > cur.duration:
      controller.asyncQueue.delete(i)
    i -= 1

proc beginEnemyAttack(battle: BattleData, controller: BattleController) =
  let
    enemy = battle.activeEntity
    skill = allSkills[enemy.knownSkills[0]]
  battle.startAttack(controller, skill, enemy, battle.player)

proc battleUpdate*(battle: BattleData, controller: BattleController, dt: float) =
  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false
    return

  controller.updateFloatingText(dt)
  controller.updateVfx(dt)
  controller.updateEventQueue(dt)
  controller.updateAsyncQueue(dt)

  if controller.noAnimationPlaying():
    battle.updateTurnQueue(dt)
    if battle.isEnemyTurn:
      battle.beginEnemyAttack(controller)

  battle.clampResources()

method pushMenus(controller: BattleController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]
