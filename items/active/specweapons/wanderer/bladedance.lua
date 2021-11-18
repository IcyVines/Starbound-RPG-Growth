require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Melee primary ability
BladeDance = WeaponAbility:new()

function BladeDance:init()
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns["Unsheathe"]

  self.killTimer = 0
  self.altKillTimer = 0
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.weapon.active = config.getParameter("unsheathed", false)
  self.bonusPower = config.getParameter("bonusPower", 1)
  self.projectileIds = {}

  self.previousComboType = nil

  self.animKeyPrefix = self.animKeyPrefix or ""
  if self.weapon.active then
    self.weapon:setStance(self.stances.idleActive)
    animator.setAnimationState("sheath", "off")
    animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle", "directives", "")
  else
    self.weapon:setStance(self.stances.idle)
    animator.setAnimationState("sheath", "on")
  end

  self.weapon.onLeaveAbility = function()
    if self.weapon.active then
      self.weapon:setStance(self.stances.idleActive)
      animator.setPartTag("blade", "directives", "")
      animator.setPartTag("handle", "directives", "")
    else
      self.weapon:setStance(self.stances.idle)
    end
  end
end

-- Ticks on every update regardless if this is the active ability
function BladeDance:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.movingForward = mcontroller.facingDirection() == mcontroller.movingDirection()
  self.notMoving = not (mcontroller.running() or mcontroller.walking())
  self.crouched = mcontroller.crouching()
  self.aerial = not mcontroller.onGround() and not mcontroller.groundMovement()

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", "")
    end
  end

  activeItem.setInstanceValue("unsheathed", self.weapon.active)
  activeItem.setInstanceValue("bonusPower", self.bonusPower)

  if self.weapon.stance.flipx then
    animator.setPartTag("blade", "directives", "?flipx")
    animator.setPartTag("handle", "directives", "?flipx")
    animator.setPartTag("sheath", "directives", "?flipx")
  else
    --[[animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle", "directives", "")
    animator.setPartTag("sheath", "directives", "")]]
  end

  self:updateDamageGiven()

  self.killTimer = math.max(self.killTimer - dt, 0)
  self.altKillTimer = math.max(self.altKillTimer - dt, 0)

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= fireMode and (fireMode == "primary" or fireMode == "alt") then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if not self.weapon.currentAbility then
    if self:shouldActivate() then
      self.currentFireMode = self.fireMode
      self:setState(self.windup)
    else

    end
  end
end

function BladeDance:updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if "ivrpgwandererkatana" == notification.damageSourceKind then
        if notification.healthLost > 0 and notification.damageDealt > notification.healthLost then
          self.killTimer = 3
        end
      elseif "ivrpgwandererkatanasheathe" == notification.damageSourceKind then
        if notification.healthLost > 0 and notification.damageDealt > notification.healthLost then
          self.altKillTimer = 3
        end
      end
    end
  end
end

-- State: windup
function BladeDance:windup()
  if not self.weapon.active then
    self.comboType = "Unsheathe"
    animator.setGlobalTag("hueshift", self.bonusPower ~= 1 and "hueshift=0" or "hueshift=280")
  elseif self.fireMode == "primary" then
    if self.aerial and not self.shiftHeld then
      self.comboType = "Dive"
    else
      if self.previousComboType == "Primary" or self.previousComboType == "Dive" then
        self.comboType = "Primary2"
      else
        self.comboType = "Primary"
      end
    end
  else --alt
    if self.shiftHeld then
      self.comboType = "Sheathe"
    elseif self.movingForward and not self.notMoving and not self.aerial then
      self.comboType = "Lunge"
    elseif not self.movingForward and not self.notMoving and not self.aerial then
      self.comboType = "Backstep"
    else
      self.comboType = "Rise"
    end
  end

  local stance = self.stances["windup"..self.comboType]

  if not self.weapon.active then
    animator.setAnimationState("sheath", "transitionOff")
    animator.playSound("unsheathe")
  end

  self.weapon:setStance(stance)

  if stance.flipx and stance.flipy then
    animator.setPartTag("blade", "directives", "?flipxy")
    animator.setPartTag("handle", "directives", "?flipxy")
  elseif stance.flipx and not stance.flipy then
    animator.setPartTag("blade", "directives", "?flipx")
    animator.setPartTag("handle", "directives", "?flipx")
  elseif stance.flipy and not stance.flipx then
    animator.setPartTag("blade", "directives", "?flipy")
    animator.setPartTag("handle", "directives", "?flipy")
  else
    animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle","directives", "")
  end
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

  if self.stances["preslash"..self.comboType] then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: wait
-- waiting for next combo input
function BladeDance:wait()
  local stance = self.stances["wait"..self.comboType]
  self.previousComboType = self.comboType

  self.weapon:setStance(stance)
  if stance.flipx and stance.flipy then
    animator.setPartTag("blade", "directives", "?flipxy")
    animator.setPartTag("handle", "directives", "?flipxy")
  elseif stance.flipx and not stance.flipy then
    animator.setPartTag("blade", "directives", "?flipx")
    animator.setPartTag("handle", "directives", "?flipx")
  elseif stance.flipy and not stance.flipx then
    animator.setPartTag("blade", "directives", "?flipy")
    animator.setPartTag("handle", "directives", "?flipy")
  else
    animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle","directives", "")
  end
  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    end
  end)
  
  self.previousComboType = false
  self.cooldownTimer = math.max(0, self.cooldowns[self.comboType] - stance.duration)
  self.comboStep = 1
end

-- State: preslash
-- brief frame in between windup and fire
function BladeDance:preslash()
  local stance = self.stances["preslash"..self.comboType]


  self.weapon:setStance(stance)
  self.weapon:updateAim()
  if stance.flipx and stance.flipy then
    animator.setPartTag("blade", "directives", "?flipxy")
    animator.setPartTag("handle", "directives", "?flipxy")
  elseif stance.flipx and not stance.flipy then
    animator.setPartTag("blade", "directives", "?flipx")
    animator.setPartTag("handle", "directives", "?flipx")
  elseif stance.flipy and not stance.flipx then
    animator.setPartTag("blade", "directives", "?flipy")
    animator.setPartTag("handle", "directives", "?flipy")
  else
    animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle","directives", "")
  end
  util.wait(stance.duration)

  self:setState(self.fire)
end

-- State: fire
function BladeDance:fire()
  local stance = self.stances["fire"..self.comboType]

  self.weapon:setStance(stance)
  self.weapon:updateAim()
  if stance.flipx and stance.flipy then
    animator.setPartTag("blade", "directives", "?flipxy")
    animator.setPartTag("handle", "directives", "?flipxy")
  elseif stance.flipx and not stance.flipy then
    animator.setPartTag("blade", "directives", "?flipx")
    animator.setPartTag("handle", "directives", "?flipx")
  elseif stance.flipy and not stance.flipx then
    animator.setPartTag("blade", "directives", "?flipy")
    animator.setPartTag("handle", "directives", "?flipy")
  else
    animator.setPartTag("blade", "directives", "")
    animator.setPartTag("handle","directives", "")
  end
  local animStateKey = self.animKeyPrefix .. "fire" .. self.comboType
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  local unsheatheDamageConfig = false
  if self.comboType == "Unsheathe" then
    if self.bonusPower == 3 then
      world.spawnProjectile("ivrpgwnomadicsoulswoosh", vec2.add(mcontroller.position(), {mcontroller.facingDirection() * 2, 0}), activeItem.ownerEntityId(), {mcontroller.facingDirection(), 0}, false, {power = self.stepDamageConfig["Unsheathe"].baseDamageFactor * self.baseDps * self.fireTime * 2, powerMultiplier = activeItem.ownerPowerMultiplier(), speed = 50})
    end
    unsheatheDamageConfig = copy(self.stepDamageConfig[self.comboType])
    unsheatheDamageConfig.baseDamage = unsheatheDamageConfig.baseDamage * self.bonusPower
  elseif self.comboType == "Backstep" then
    mcontroller.setVelocity({-mcontroller.facingDirection() * 100, 1})
  elseif self.comboType == "Lunge" then
    mcontroller.setVelocity({mcontroller.facingDirection() * 100, 1})
  elseif self.comboType == "Rise" then
    mcontroller.setVelocity({0, 100})
  elseif self.comboType == "Dive" then
    mcontroller.setVelocity({mcontroller.facingDirection() * 20, -100})
    self.projectileIds[1] = world.spawnProjectile("ivrpgnomadicsouldive", mcontroller.position(), activeItem.ownerEntityId(), {mcontroller.facingDirection(),0}, true, {power = self.stepDamageConfig["Dive"].baseDamageFactor * self.baseDps * self.fireTime * 5, powerMultiplier = activeItem.ownerPowerMultiplier()})
    world.spawnProjectile("ivrpgwnomadicsoulswoosh", vec2.add(mcontroller.position(), {mcontroller.facingDirection() * 2, -2}), activeItem.ownerEntityId(), {mcontroller.facingDirection() * 0.5,-1}, false, {speed = 100, power = self.stepDamageConfig["Dive"].baseDamageFactor * self.baseDps * self.fireTime * 2, powerMultiplier = activeItem.ownerPowerMultiplier(), timeToLive = 1})
  end

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    if self.comboType ~= "Dive" then
      self.weapon:setDamage(unsheatheDamageConfig or self.stepDamageConfig[self.comboType], damageArea)
    else
      status.setPersistentEffects("ivrpgnomadicsouldive", {{stat = "fallDamageMultiplier", effectiveMultiplier = 0}})
    end
    if self.comboType == "Rise" then
      mcontroller.controlApproachYVelocity(0, 450)
    elseif self.comboType == "Lunge" or self.comboType == "Backstep" then
      mcontroller.controlApproachXVelocity(0, 400)
    elseif self.comboType == "Dive" and (mcontroller.onGround() or mcontroller.groundMovement()) then
      for i,id in ipairs(self.projectileIds) do
        if world.entityExists(id) then
          world.callScriptedEntity(id, "die")
        end
      end
      return true
    end
  end)
  self.projectileIds = {}
  self.comboStep = 1
  status.clearPersistentEffects("ivrpgnomadicsouldive")
  if not self.weapon.active then
    self:setState(self.cooldown)
  elseif self.comboType == "Sheathe" then
    self:setState(self.cooldown)
  else--if self.comboStep < self.comboSteps then
    self:setState(self.wait)
  --[[else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1]]
  end
end

function BladeDance:cooldown()
  local stance = "toIdle"
  local stanceTo = "idleActive"
  if self.weapon.active then
    stance = "toSheathed"
    stanceTo = "idle"
    animator.setAnimationState("sheath", "transitionOn")
  end
  self.weapon:setStance(self.stances[stance])
  self.weapon:updateAim()

  self.bonusPower = 1
  if self.comboType == "Sheathe" then
    if self.altKillTimer > 0 then
      self.bonusPower = 3
    elseif self.killTimer > 0 then
      self.bonusPower = 2
    end
    self.altKillTimer = 0
    self.killTimer = 0
  end

  self.weapon.active = not self.weapon.active

  local progress = 0
  util.wait(self.stances[stance].duration, function()
    local from = self.stances[stance].weaponOffset or {0,0}
    local to = self.stances[stanceTo].weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances[stance].weaponRotation, self.stances[stanceTo].weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances[stance].armRotation, self.stances[stanceTo].armRotation))
    
    if progress >= 0.5 and self.weapon.active then
      animator.setPartTag("blade", "directives", "")
      animator.setPartTag("handle", "directives", "")
    end

    progress = math.min(1.0, progress + (self.dt / self.stances[stance].duration))
  end)

end

function BladeDance:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      return (self.fireMode == "primary" or self.fireMode == "alt") and self.edgeTriggerTimer > 0
    end
  end
end

function BladeDance:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
  self.flashTimer = self.flashTime
end

function BladeDance:computeDamageAndCooldowns()
  local attackTimes = {}
  self.comboTypes = {Unsheathe = 0, Primary = 0, Primary2 = 0, Rise = 0, Dive = 0, Backstep = 0, Lunge = 0, Sheathe = 0}
  for k,v in pairs(self.comboTypes) do
    local attackTime = self.stances["windup"..k].duration + self.stances["fire"..k].duration
    if self.stances["preslash"..k] then
      attackTime = attackTime + self.stances["preslash"..k].duration
    end
    self.comboTypes[k] = attackTime
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  for i, attackTime in pairs(self.comboTypes) do
    self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
    self.stepDamageConfig[i].timeoutGroup = i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    local targetTime = damageFactor * self.fireTime * self.stepDamageConfig[i].baseCooldownFactor
    local speedFactor = 1.0 * (self.comboSpeedFactor)
    self.cooldowns[i] = math.max((targetTime - attackTime) * speedFactor, 0.4)
  end
end

 
function BladeDance:uninit()
  self.weapon:setDamage()
  for i,id in ipairs(self.projectileIds) do
    if world.entityExists(id) then
      world.callScriptedEntity(id, "die")
    end
  end
  status.clearPersistentEffects("ivrpgnomadicsouldive")
end