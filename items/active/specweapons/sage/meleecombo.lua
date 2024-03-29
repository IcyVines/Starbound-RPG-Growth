require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

function MeleeCombo:init()
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""
  self.elements = {"physical", "fire", "ice", "electric", "nova", "poison"}
  self.elementIndexes = {physical = 1, fire = 2, ice = 3, electric = 4, nova = 5, poison = 6}

  self.elementalType = config.getParameter("elementalType", "physical")
  self.elementIndex = self.elementIndexes[self.elementalType]

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.shiftHeld = shiftHeld

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

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if not self.weapon.currentAbility and self:shouldActivate() then
    self:setState(self.windup)
  end

  if self.active and not status.overConsumeResource("energy", self.energyPerSecond * self.dt) then
    self.active = false
  end

  if fireMode == "alt"
      and not self.weapon.currentAbility
      and self.cooldownTimer == 0
      and not status.resourceLocked("energy") then
        self:setState(self.empower)
  end
end

-- Empowered States
function MeleeCombo:empower()
  self.weapon:setStance(self.stances.empower)

  activeItem.setCursor("/cursors/charge2.cursor")
  local progress = 0
  while progress < self.stances.empower.durationBefore and self.fireMode == "alt" do
    progress = progress + self.dt
    coroutine.yield()
  end

  if progress < self.stances.empower.durationBefore then
    self:reset()
    return
  end

  animator.setAnimationState("elementalType", "holy")
  --self.active = true
  while self.fireMode == "alt" do
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")
    mcontroller.controlModifiers({runningSuppressed = true})

    if targetValid and status.overConsumeResource("energy", 20) then
      self:spawnBeam()
    end

    coroutine.yield()
  end
  
  util.wait(self.stances.empower.durationAfter)
  self:reset()
end

function MeleeCombo:reset()
  activeItem.setCursor("/cursors/pointer.cursor")
  animator.setAnimationState("elementalType", self.elementalType)
  local tooltipFields = {damageKindImage = "/interface/elements/"..self.elementalType..".png"}
  activeItem.setInventoryIcon("/items/active/specweapons/sage/" .. self.elementalType .. "rapture.png")
  activeItem.setInstanceValue("tooltipFields", tooltipFields)
end

function MeleeCombo:targetValid(aimPos)
  local focusPos = mcontroller.position()
  return world.magnitude(focusPos, aimPos) <= (self.maxCastRange or 30)
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not world.lineTileCollision(focusPos, aimPos)
end

function MeleeCombo:spawnBeam()
  self.timer = 0
  self.spawnPosition = activeItem.ownerAimPosition()
  self.randomDirection = math.random(-2,2)
  world.spawnProjectile("ivrpgraptureholygate", self.spawnPosition, activeItem.ownerEntityId(), {0.1 * self.randomDirection, -1}, false, {timeToLive = 0.8, speed = 0})
  animator.playSound("empower")
  self.reap = true
  util.wait(0.5, function()
    local params = {curveDirection = self.randomDirection, timeToLive = 0.3, speed = 70}
    if self.reap then
      params.actionOnReap = {{action = "projectile", type = "ivrpgraptureholygate", config = {timeToLive = 0.5}}}
      self.reap = false
    end
    world.spawnProjectile("ivrpgrapturebeam", self.spawnPosition, activeItem.ownerEntityId(), {0.1 * self.randomDirection, -1}, false, params)
  end)
end

function MeleeCombo:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function MeleeCombo:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function MeleeCombo:changeElement()
  self.elementIndex = (self.elementIndex % 5) + 1
  self.elementalType = self.elements[self.elementIndex]
  local tooltipFields = {damageKindImage = "/interface/elements/"..self.elementalType..".png"}
  activeItem.setInventoryIcon("/items/active/specweapons/sage/" .. self.elementalType .. "rapture.png")
  activeItem.setInstanceValue("tooltipFields", tooltipFields)
end
-- State: windup
function MeleeCombo:windup()
  local stance = self.stances["windup"..self.comboStep]

  if self.shiftHeld then
    self:changeElement()
  end

  self.weapon:setStance(stance)

  self.edgeTriggerTimer = 0

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    util.wait(stance.duration - (self.active and 0.075 or 0))
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

-- State: wait
-- waiting for next combo input
function MeleeCombo:wait()
  local stance = self.stances["wait"..(self.comboStep - 1)]

  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    end
  end)

  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  self.comboStep = 1
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
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = (self.weapon.elementalType == "physical" and "" or self.weapon.elementalType) .. self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
  end)

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep] - (self.active and 0.2 or 0)
    self.comboStep = 1
  end
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

function MeleeCombo:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
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
    --The following line changes the damagesource. Not sure why it doesn't work automatically, but whatever.
    self.stepDamageConfig[i].damageSourceKind = self.damageConfig.damageSourceKind

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
  end
end

function MeleeCombo:uninit()
  self.weapon:setDamage()
end