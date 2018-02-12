require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.name = item.name()
  self.elementalType = self.elementalType or self.weapon.elementalType

  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.stances = config.getParameter("stances")

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  self.element = self.elementalType == "physical" and "nova" or self.elementalType
  self:updateProjectiles()

  self.passedPrime = status.statPositive("ivrpgucpassedprime") and self.name == "wizardnovastaff3"
  self.quicksilver = status.statPositive("ivrpgucquicksilver") and self.name == "wizardnovastaff3"
  world.debugPoint(self:focusPosition(), "blue")

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then
      self:setState(self.charge)
  end
end

function ControlProjectile:charge()
  self.weapon:setStance(self.stances.charge)


  local chargeTimer = self.stances.charge.duration
  if self.quicksilver then 
    chargeTimer = chargeTimer / 2
    animator.setAnimationRate(2)
  end

  animator.playSound(self.elementalType.."charge")
  animator.setAnimationState((self.elementalType == "physical" and "nova" or self.elementalType).."charge", "charge")
  animator.setParticleEmitterActive((self.elementalType == "physical" and "nova" or self.elementalType) .. "Charge", true)
  activeItem.setCursor("/cursors/charge2.cursor")



  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})
    if self.passedPrime then
      status.overConsumeResource("energy", 0)
    end

    coroutine.yield()
  end

  if self.passedPrime then
    status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor)
  end

  animator.stopAllSounds(self.elementalType.."charge")
  animator.setAnimationRate(1)
  if chargeTimer <= 0 then
    self:setState(self.charged)
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
  end
end

function ControlProjectile:charged()
  self.weapon:setStance(self.stances.charged)

  animator.playSound(self.elementalType.."fullcharge")
  animator.playSound(self.elementalType.."chargedloop", -1)
  animator.setParticleEmitterActive((self.elementalType == "physical" and "nova" or self.elementalType) .. "Charge", true)

  local targetValid
  self.bonusDamage = 1
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

    mcontroller.controlModifiers({runningSuppressed=true})

    if self.passedPrime then
      if status.overConsumeResource("energy", self.dt * self.baseDamageFactor * 25) then
        self.bonusDamage = self.bonusDamage + self.dt*0.3
      else
        status.setResource("energy", 0)
      end
    end

    coroutine.yield()
  end

  self:setState(self.discharge)
end

function ControlProjectile:discharge()
  self.weapon:setStance(self.stances.discharge)

  activeItem.setCursor("/cursors/reticle0.cursor")

  if self.passedPrime then
    if self:targetValid(activeItem.ownerAimPosition()) then
      animator.playSound(self.elementalType.."activate")
      self:createProjectiles()
    else
      animator.playSound(self.elementalType.."discharge")
      self:setState(self.cooldown)
      return
    end
  else
    if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then
      animator.playSound(self.elementalType.."activate")
      self:createProjectiles()
    else
      animator.playSound(self.elementalType.."discharge")
      self:setState(self.cooldown)
      return
    end
  end

  util.wait(self.stances.discharge.duration, function(dt)
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end)

  while #storage.projectiles > 0 do
    if self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.lastFireMode ~= self.fireMode then
      self:killProjectiles()
    end
    self.lastFireMode = self.fireMode

    status.setResourcePercentage("energyRegenBlock", 1.0)
    coroutine.yield()
  end

  animator.playSound(self.elementalType.."discharge")
  animator.stopAllSounds(self.elementalType.."chargedloop")

  self:setState(self.cooldown)
end

function ControlProjectile:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon.aimAngle = 0

  animator.setAnimationState((self.elementalType == "physical" and "nova" or self.elementalType).."charge", "discharge")
  animator.setParticleEmitterActive((self.elementalType == "physical" and "nova" or self.elementalType) .. "Charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function ControlProjectile:targetValid(aimPos)
  local focusPos = self:focusPosition()
  if self.quicksilver then
    self.bonusRange = 10
  else 
    self.bonusRange = 0
  end
  return world.magnitude(focusPos, aimPos) <= (self.maxCastRange + self.bonusRange)
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not world.lineTileCollision(focusPos, aimPos)
end

function ControlProjectile:createProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
  local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
  local basePos = activeItem.ownerAimPosition()

  local pCount = self.projectileCount or 1

  local pParams = copy(self.projectileParameters)
  --pParams.statusEffects = {"wizardnovastatus"}
  self.projectileType = self.name == "wizardnovastaff3" and "primednovaexplosion" or self.projectileType
  self.powerMod = self.elementalType == "ice" and 20 or (self.elementalType == "fire" and -20 or 0)
  if self.quicksilver then
    self.quicksilverPower = 50
  else
    self.quicksilverPower = 0
  end
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") * self.bonusDamage / pCount + self.powerMod - self.quicksilverPower
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

  for i = 1, pCount do
    local projectileId = world.spawnProjectile(
        (self.elementalType == "physical" and "nova" or self.elementalType) .. self.projectileType .. (self.passedPrime and "passed" or ""),
        vec2.add(basePos, pOffset),
        activeItem.ownerEntityId(),
        pOffset,
        false,
        pParams
      )

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end

    pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
  end
end

function ControlProjectile:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
function ControlProjectile:updateProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local newProjectiles = {}
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
      if projectileResponse:finished() then
        local newIds = projectileResponse:result()
        if type(newIds) ~= "table" then
          newIds = {newIds}
        end
        for _, newId in pairs(newIds) do
          table.insert(newProjectiles, newId)
        end
      end
    end
  end
  storage.projectiles = newProjectiles
end

function ControlProjectile:killProjectiles()
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      world.sendEntityMessage(projectileId, "kill")
    end
  end
end

function ControlProjectile:reset()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState((self.elementalType == "physical" and "nova" or self.elementalType).."charge", "idle")
  animator.setParticleEmitterActive((self.elementalType == "physical" and "nova" or self.elementalType) .. "Charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function ControlProjectile:uninit(weaponUninit)
  self:reset()
  if weaponUninit then
    self:killProjectiles()
  end
end
