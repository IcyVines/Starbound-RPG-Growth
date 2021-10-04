require "/scripts/keybinds.lua"

function init()
  self.bonePteropod = root.assetJson("/monsters/flyers/bonepteropod/bonepteropod.monstertype")
  self.healthCost = config.getParameter("healthCost", 5)
  self.cooldown = config.getParameter("cooldown", 5)
  self.cooldownTimer = 0
  self.rechargeTimer = 0
  self.mobCharge = 0
  self.damageGivenUpdate = 5
  self.currentMobCount = 0
  self.id = entity.id()
  Bind.create("f", reap)

  message.setHandler("enemyReaped", function(_, _)
    self.mobCharge = self.mobCharge + 1
  end)

  message.setHandler("bonePteropodDefeated", function(_, _)
    self.currentMobCount = math.max(self.currentMobCount - 1, 0)
  end)

  message.setHandler("bonePteropodTransfer", function(_, _, damage)
    status.modifyResource("health", damage)
  end)
end

function reset()
  animator.setAnimationState("soul", "off")
  for i=1,6 do
    animator.setGlobalTag("charged" .. i, "empty")
  end
end

function uninit()
  tech.setParentDirectives()
  reset()
end

function reap()

  local intelligence = status.statusProperty("ivrpgintelligence", 1)

  if self.cooldownTimer == 0 and (not status.statPositive("activeMovementAbilities")) and self.shiftHeld and self.mobCharge > 0 then
    self.cooldownTimer = self.cooldown
    animator.playSound("reap")
    self.mobCharge = math.floor(math.min(self.mobCharge^(1 + intelligence/100), 6))
    local params = {}
    params.statusSettings = self.bonePteropod.baseParameters.statusSettings
    params.statusSettings.stats.maxHealth.baseValue = status.stat("maxHealth")
    params.statusSettings.stats.protection.baseValue = status.stat("protection")
    params.statusSettings.stats.powerMultiplier.baseValue = status.stat("powerMultiplier")
    params.level = 1
    params.damageTeamType = "friendly"
    params.aggressive = true
    params.ownerUuid = entity.uniqueId()
    params.ownerId = self.id
    while self.mobCharge > 0 do 
      world.spawnMonster("bonepteropod", mcontroller.position(), params)
      self.mobCharge = self.mobCharge - 1
      self.currentMobCount = self.currentMobCount + 1
    end
    reset()
    return
  end

  if self.cooldownTimer == 0 and (not status.statPositive("activeMovementAbilities")) and status.consumeResource("health", self.healthCost) then
    self.cooldownTimer = self.cooldown
    animator.playSound("reap")
    local damageConfig = {
      power = intelligence^0.75 + 9
    }
    world.spawnProjectile("ivrpgreapexplosion", {mcontroller.xPosition(), mcontroller.yPosition() - 0.25}, self.id, nil, true, damageConfig)
  end
end

function update(args)
  self.shiftHeld = not args.moves["run"]

  local intelligence = status.statusProperty("ivrpgintelligence", 1)
  local mobCharge = math.floor(math.min(self.mobCharge^(1 + intelligence/100), 6))
  if mobCharge > 0 then
    animator.setAnimationState("soul", "on")
  end
  for i=1,mobCharge do
    animator.setGlobalTag("charged" .. i, "full")
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      animator.playSound("recharge")
      self.rechargeTimer = 0.1
      tech.setParentDirectives("?fade=000000=0.25")
    end
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(self.rechargeTimer - args.dt, 0)
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
    end
  end
end