require "/scripts/util.lua"
require "/scripts/vec2.lua"

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

function MeleeCombo:init()
  message.setHandler("killedEnemyDarkTemplar", function(_, _, enemyLevel, damageKind, bledToDeath)
    if bledToDeath and bledToDeath == "demonichalberdheartless" or damageKind == "demonichalberdheartless" then
      local killCount = config.getParameter("killCount", 0)
      activeItem.setInstanceValue("killCount", killCount + 1)
    end
  end)

  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0
  self.stepExplosionConfig = config.getParameter("primaryAbility.stepExplosionConfig", {})
  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.killDirectives = ""
  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.killCount = config.getParameter("killCount", 0)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", self.killDirectives)
    end
  end

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode



  if not self.weapon.currentAbility then
    if self:shouldActivate() then
      self:setState(self.windup)
    elseif fireMode == "alt" and self.cooldownTimer == 0 then
      self:setState(self.windupstab)
    end
  end

  animator.setParticleEmitterActive("demonicEmbers", self.killCount >= 1)
  animator.setParticleEmitterActive("demonicSparks", self.killCount >= 10)
  animator.setParticleEmitterEmissionRate("demonicEmbers", math.min(10, self.killCount))
  if self.killCount >= 10 then
    if self.weapon.tickExplodingTimer and self.explodingTimer > 0 then
      self.explodingTimer = self.explodingTimer - dt
      if self.explodingTimer <= 0 then
        self.weapon.tickExplodingTimer = false
        self.explodingTimer = 0
        self.killCount = 0
        self.killFlashed = false
        self.killDirectives = ""
        animator.setGlobalTag("bladeDirectives", self.killDirectives)
        activeItem.setInstanceValue("killCount", 0)
      end
    else
      self.killDirectives = "?fade=770000=0.5"
      if not self.killFlashed then
        animator.setGlobalTag("bladeDirectives", self.killDirectives)
        self.killFlashed = true
      end
      self.explodingTimer = 10
    end
  end

end

-- State: windup
function MeleeCombo:windup()
  local stance = self.stances["windup"..self.comboStep]

  self.weapon:setStance(stance)

  self.edgeTriggerTimer = 0

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    util.wait(stance.duration)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances["preslash"..self.comboStep] then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

function MeleeCombo:windupstab()
  if self.comboStep == 2 then
    self.weapon:setStance(self.stances.windup2)
    util.wait(self.stances.windup2.duration)
  else
    self.weapon:setStance(self.stances.windupstab)
    util.wait(self.stances.windupstab.duration)
  end
  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end
  self:setState(self.firestab)
end

-- State: wait
-- waiting for next combo input
function MeleeCombo:wait()
  local stance = self.stances["wait"..((self.comboStep == 6 or self.comboStep == 1) and 1 or self.comboStep - 1)]

  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    elseif self.comboStep == 2 and self.fireMode == "alt" and self.cooldownTimer == 0 then
      self:setState(self.windupstab)
      return
    end
  end)

  self.cooldownTimer = math.max(0, self.cooldowns[(self.comboStep == 6 or self.comboStep == 1) and 1 or self.comboStep - 1] - stance.duration)
  self.comboStep = 1
  self.weapon.aimAngle = 0
end

-- State: preslash
-- brief frame in between windup and fire
function MeleeCombo:preslash()
  local stance = self.stances["preslash"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration)

  self:setState(self.fire)
end

-- State: fire
function MeleeCombo:fire()
  if self.comboStep == 6 then
    self.weapon.aimAngle = 0
  end
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. ((self.comboStep > 1 and self.comboStep < 6) and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. "physicalswoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep == 6 and 1 or self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  local stepDamageConfig = false
  if self.comboStep == 6 then
    stepDamageConfig = copy(self.stepDamageConfig[1])
    stepDamageConfig.baseDamage = stepDamageConfig.baseDamage * 0.75
  end

  if self.comboStep == 1 and self.explodingTimer and self.explodingTimer > 0 then
    self.weapon.tickExplodingTimer = true
  end

  if self.weapon.tickExplodingTimer and self.explodingTimer and self.explodingTimer > 0 then
    local explosionConfig = self.stepExplosionConfig[self.comboStep]
    local power = stepDamageConfig and stepDamageConfig.baseDamage or self.stepDamageConfig[self.comboStep].baseDamage
    local offset = vec2.rotate(explosionConfig.offset, self.weapon.aimAngle)
    offset[1] = offset[1] * mcontroller.facingDirection()
    world.spawnProjectile(explosionConfig.type, vec2.add(mcontroller.position(), offset), activeItem.ownerEntityId(), {0,0}, false, {power = power, powerMultiplier = activeItem.ownerPowerMultiplier()})
    if self.comboStep == 4 then
      explosionConfig = self.stepExplosionConfig[7]
      offset = vec2.rotate(explosionConfig.offset, self.weapon.aimAngle)
      offset[1] = offset[1] * mcontroller.facingDirection()
      world.spawnProjectile(explosionConfig.type, vec2.add(mcontroller.position(), offset), activeItem.ownerEntityId(), {0,0}, false, {power = power, powerMultiplier = activeItem.ownerPowerMultiplier()})
    end
  end

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh", self.comboStep == 6 and "damageAreaSpecial")
    self.weapon:setDamage(stepDamageConfig or self.stepDamageConfig[self.comboStep], damageArea)
  end)

  if self.comboStep < self.comboSteps then
    if self.weapon.aimAngle < math.pi / 6 then
      self.weapon.aimAngle = 0
      self.comboStep = self.comboStep + 1
    elseif self.comboStep == 2 then
      self.comboStep = 6
    end
    self:setState(self.wait)
  elseif self.comboStep == 6 then
    self.weapon.aimAngle = 0
    self.comboStep = 3
    self:setState(self.wait)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1
  end
end

-- State: fire
function MeleeCombo:firestab()
  self.weapon:setStance(self.stances.firestab)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "firestab")
  animator.playSound(self.fireSound or "fire")
  animator.burstParticleEmitter("physicalswoosh")

  local stepDamageConfig = copy(self.stepDamageConfig[4])
  stepDamageConfig.knockback = 70

  if self.comboStep ~= 2 and self.explodingTimer and self.explodingTimer > 0 then
    self.weapon.tickExplodingTimer = true
  end

  if self.weapon.tickExplodingTimer and self.explodingTimer and self.explodingTimer > 0 then
    local explosionConfig = self.stepExplosionConfig[5]
    local power = stepDamageConfig and stepDamageConfig.baseDamage or self.stepDamageConfig[5].baseDamage
    local offset = vec2.rotate(explosionConfig.offset, self.weapon.aimAngle)
    offset[1] = offset[1] * mcontroller.facingDirection()
    world.spawnProjectile(explosionConfig.type, vec2.add(mcontroller.position(), offset), activeItem.ownerEntityId(), {0,0}, false, {power = power, powerMultiplier = activeItem.ownerPowerMultiplier()})
  end

  self.moveTimer = self.stances.firestab.duration
  util.wait(self.stances.firestab.duration, function()
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(stepDamageConfig, damageArea, self.fireTime)
    mcontroller.controlApproachVelocity({mcontroller.facingDirection() * 100 * (self.moveTimer / self.stances.firestab.duration), 0.1}, 1500)
    status.setPersistentEffects("ivrpgheartlessarmor", {
      {stat = "grit", amount = 1},
      {stat = "protection", amount = 30}
    })
    mcontroller.controlModifiers({
      movementSuppressed = true,
      jumpingSuppressed = true
    })
    self.moveTimer = self.moveTimer - self.dt
    if self.moveTimer < 0.2 and self:shouldActivate() then
      self.comboStep = 3
      status.clearPersistentEffects("ivrpgheartlessarmor")
      self:setState(self.windup)
      return
    else
      self.comboStep = 1
    end
  end)
  
  status.clearPersistentEffects("ivrpgheartlessarmor")
  self.cooldownTimer = self:getCooldownTime()
end

function MeleeCombo:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      return self.fireMode == (self.activatingFireMode or self.abilitySlot)
    end
  end
end

function MeleeCombo:getCooldownTime()
  return self.fireTime - (self.stances.windupstab.duration + self.stances.firestab.duration) / 2
end

function MeleeCombo:readyFlash(color)
  animator.setGlobalTag("bladeDirectives", self.killDirectives .. "?" .. (color or self.flashDirectives))
  self.flashTimer = self.flashTime
end

function MeleeCombo:computeDamageAndCooldowns()
  local attackTimes = {}
  for i = 1, self.comboSteps do
    local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
    if self.stances["preslash"..i] then
      attackTime = attackTime + self.stances["preslash"..i].duration
    end
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  for i, attackTime in ipairs(attackTimes) do
    self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
    self.stepDamageConfig[i].timeoutGroup = "primary"..i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
  end
end

function MeleeCombo:uninit()
  status.clearPersistentEffects("ivrpgheartlessarmor")
  self.weapon:setDamage()
end