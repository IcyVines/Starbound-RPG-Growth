require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Charge = WeaponAbility:new()

function Charge:init()
  self:reset()
  self.holdDamageConfig = config.getParameter("altAbility.holdDamageConfig", {})
  self.holdDamageMultiplier = config.getParameter("altAbility.holdDamageMultiplier", 0.1)
  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
  self.id = activeItem.ownerEntityId()
  self.maxLightning = {
    {36, 22, 65, 255},
    {204, 0, 22, 255}
  }
end

function Charge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.powerMultiplier = activeItem.ownerPowerMultiplier()
  self.class = world.entityCurrency(self.id, "classtype") or 4

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and not status.resourceLocked("energy") then
    self:setState(self.charge)
  end
end

function Charge:charge()
  self.weapon:setStance(self.stances.charge)
  self.weapon:updateAim()

  animator.setAnimationState("dashSwoosh", "charge")

  local chargeTimer = 0
  local chargeLevel = 0

  local damageArea = partDamageArea("blade")

  while self.fireMode == "alt" and (chargeLevel == self.chargeLevels or status.overConsumeResource("energy", (self.maxEnergyUsage / self.chargeTime) * self.dt)) do
    chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)
    chargeLevel = self:setChargeLevel(chargeTimer, chargeLevel)
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    coroutine.yield()
  end

  if chargeTimer > self.minChargeTime then
    self:setState(self.dash, chargeTimer / self.chargeTime)
  end
end

function Charge:dash(charge)
  self.weapon:setStance(self.stances.dash)
  self.weapon:updateAim()

  self:setLightning(3, self.dashLightning[1], self.dashLightning[2], self.dashLightning[3], self.dashLightning[4], 8)

  animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")
  animator.setAnimationState("swoosh", "fire")
  animator.setAnimationState("dashSwoosh", "full")
  animator.playSound("fire")

  local positionModifier = {mcontroller.facingDirection() * 6 * math.cos(self.weapon.aimAngle), 6 * math.sin(self.weapon.aimAngle)}
  self.initialPosition = vec2.add(vec2.add(mcontroller.position(), activeItem.handPosition()), positionModifier)

  util.wait(self.maxDashTime * charge^0.33, function(dt)
    local aimDirection = {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}
    mcontroller.controlApproachVelocity(vec2.mul(aimDirection, self.dashMaxSpeed), self.dashControlForce)
    status.setPersistentEffects("ivrpgdragonsbane", {
      {stat = "protection", amount = 40},
      {stat = "physicalResistance", amount = 0.25},
      {stat = "electricStatusImmunity", amount = 1},
      {stat = "electricResistance", amount = 1}
    })
    mcontroller.controlParameters({
      airFriction = 0,
      groundFriction = 0,
      liquidFriction = 0,
      gravityEnabled = false
    })

    local damageArea = partDamageArea("dashSwoosh")
    self.damageConfig.baseDamage = self.baseDps * self.chargeTime * charge
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  self.endPosition =  vec2.add(vec2.add(mcontroller.position(), activeItem.handPosition()), positionModifier)
  local directionTo = world.distance(self.endPosition, self.initialPosition)
  local magnitude = vec2.mag(directionTo)

  local maxLightning = self.maxLightning[self.class == 1 and 1 or 2]
  maxLightning[4] = 255*charge
  self:setLightning(3, 2, 0, self.dashLightning[3], maxLightning, magnitude, true)

  directionTo = world.distance(self.endPosition, self.actualPosition)
  magnitude = vec2.mag(directionTo)
  local speed = magnitude / 0.1

  world.spawnProjectile("lightningthrower", self.actualPosition, self.id, {0,0}, false, {
    power = self.damageConfig.projectileDamage * self.powerMultiplier * charge * 0.2,
    statusEffects = {"ivrpgoverload"},
    timeToLive = 0.36
  })

  world.spawnProjectile("lightningthrower", self.endPosition, self.id, {0,0}, false, {
    power = self.damageConfig.projectileDamage * self.powerMultiplier * charge * 0.2,
    statusEffects = {"ivrpgoverload"},
    timeToLive = 0.36
  })

  world.spawnProjectile("ivrpgdragonsbaneprojectile", self.actualPosition, self.id, directionTo, false, {
    power = self.damageConfig.projectileDamage * self.powerMultiplier * charge,
    speed = speed
  })

  animator.playSound("bolt")
  -- freeze in mid air for a short amount of time
  util.wait(self.freezeTime, function(dt)
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setVelocity({0,0})
  end)

  status.clearPersistentEffects("ivrpgdragonsbane")
end

function Charge:reset()
  activeItem.setScriptedAnimationParameter("lightning", {})
  animator.setAnimationState("dashSwoosh", "idle")
  status.clearPersistentEffects("ivrpgdragonsbane")
end

function Charge:uninit()
  self:reset()
  if self.weapon.currentState == self.dash then
    mcontroller.setVelocity({0,0})
  end
end

function Charge:setChargeLevel(chargeTimer, currentLevel)
  local level = math.min(self.chargeLevels, math.ceil(chargeTimer / self.chargeTime * self.chargeLevels))
  if currentLevel < level then
    local classMod = self.class == 1 and 1 or 2
    local lightningCharge = self.lightningChargeLevels[classMod][level]
    self:setLightning(3, lightningCharge[1], lightningCharge[2], lightningCharge[3], lightningCharge[4], 3 + level)
  end
  return level
end

function Charge:setLightning(amount, width, forks, branching, color, length, followUp)
  local lightning = {}
  for i = 1, amount do
    local bolt = {
      minDisplacement = followUp and 0.05 or 0.125,
      forks = forks,
      forkAngleRange = 0.75,
      width = width,
      color = color,
      endPointDisplacement = -branching + (followUp and branching or (i * 2 * branching))
    }
    if not followUp then
      bolt.itemStartPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0}), self.weapon.relativeWeaponRotation)
      bolt.itemEndPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0 - length}), self.weapon.relativeWeaponRotation)
      bolt.displacement = vec2.mag(vec2.sub(bolt.itemEndPosition, bolt.itemStartPosition)) / 4
    else
      bolt.itemStartPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0 - length}), self.weapon.relativeWeaponRotation)
      bolt.itemEndPosition = vec2.rotate(vec2.add(self.weapon.weaponOffset, {0, 4.0}), self.weapon.relativeWeaponRotation)
      if i == 1 then 
        local m2 = bolt.itemEndPosition[1]
        local m1 = bolt.itemStartPosition[1]
        self.actualPosition = vec2.add(self.endPosition, {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle)*(m1-m2-1.9), math.sin(self.weapon.aimAngle)*(m1-m2-1.9)})
      end
      bolt.displacement = vec2.mag(vec2.sub(bolt.itemEndPosition, bolt.itemStartPosition)) / 8
    end
    table.insert(lightning, bolt)
  end
  activeItem.setScriptedAnimationParameter("lightning", lightning)
end
