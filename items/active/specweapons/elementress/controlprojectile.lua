require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType

  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.durationBonus = 0
  self.baseDuration = 5
  self.projectileTimer = 0
  self.stances = config.getParameter("stances")
  self.attackSpeed = config.getParameter("primaryAbility.attackSpeed")
  self.time = "sun"
  self.elementalType = "fire"

  animator.setSoundVolume("fireactivate", 0.5)
  animator.setSoundPitch("fireactivate", 1.1)
  animator.setSoundVolume("iceactivate", 0.5)
  animator.setSoundPitch("iceactivate", 1.1)

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self:updateProjectiles()

  world.debugPoint(self:focusPosition(), "blue")

  self.dt = dt

  if world.timeOfDay() > 0.5 and self.time == "sun" then
    self.time = "moon"
    self:changeElement()
    self.elementalType = "ice"
  elseif world.timeOfDay() <= 0.5 and self.time == "moon" then
    self.time = "sun"
    self:changeElement()
    self.elementalType = "fire"
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then
    self:setState(self.charge)
  end
end

function ControlProjectile:changeElement()
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  if string.find(animator.animationState("charge"), "charged") then
    animator.setAnimationState("charge", self.time .. "charged")
  elseif string.find(animator.animationState("charge"), "idle") then
    animator.setAnimationState("charge", self.time .. "idle")
  end
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
end

function ControlProjectile:charge()
  self.weapon:setStance(self.stances.charge)

  animator.playSound(self.elementalType.."charge")
  animator.setAnimationState("charge", self.time .. "charge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  activeItem.setCursor("/cursors/charge2.cursor")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  animator.stopAllSounds("icecharge")
  animator.stopAllSounds("firecharge")

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
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  self.oldElement = self.elementalType
  animator.setAnimationState("charge", self.time .. "spark")

  self.durationBonus = 0
  local targetValid
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") do
    self.projectileTimer = math.max(self.projectileTimer - self.dt, 0)
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")
    if targetValid and self.projectileTimer == 0 and status.overConsumeResource("energy", self.energyCost) then
      self:createProjectiles()
    end
    status.setResourcePercentage("energyRegenBlock", 1.0)
    mcontroller.controlModifiers({runningSuppressed=true})

    if self.oldElement ~= self.elementalType then
      self.oldElement = self.elementalType
      animator.playSound(self.elementalType.."chargedloop", -1)
      animator.setParticleEmitterActive(self.elementalType .. "charge", true)
      animator.setAnimationState("charge", self.time .. "spark")
    end

    coroutine.yield()
  end

  self:setState(self.discharge)
end

function ControlProjectile:discharge()
  self.weapon:setStance(self.stances.discharge)

  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.discharge.duration, function(dt)
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end)

  animator.playSound(self.elementalType.."discharge")
  animator.stopAllSounds(self.elementalType.."chargedloop")

  self:setState(self.cooldown)
end

function ControlProjectile:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon.aimAngle = 0

  self.projectileTimer = 0
  animator.setAnimationState("charge", self.time .. "discharge")
  animator.setParticleEmitterActive("icecharge", false)
  animator.setParticleEmitterActive("firecharge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration)
end

function ControlProjectile:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not world.lineTileCollision(focusPos, aimPos)
end

function ControlProjectile:createProjectiles()

  self.projectileTimer = self.attackSpeed
  animator.playSound(self.elementalType.."activate")

  local aimPosition = activeItem.ownerAimPosition()
  local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
  local pOffset = {2, 0}
  local basePos = activeItem.ownerAimPosition()

  local pCount = self.projectileCount or 1

  local pParams = copy(self.projectileParameters)
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()
  pParams.timeToLive = self.baseDuration
  pParams.speed = 0
  pParams.attackTime = 0.9

  for i = 1, pCount do
    local projectileId = world.spawnProjectile(
        self.projectileType .. self.time,
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
    pParams.attackTime = pParams.attackTime + 0.2
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
      world.sendEntityMessage(projectileId, "trigger")
    end
  end
end

function ControlProjectile:reset()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState("charge", self.time .. "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function ControlProjectile:uninit(weaponUninit)
  self:reset()
  if weaponUninit then
    self:killProjectiles()
  end
end
