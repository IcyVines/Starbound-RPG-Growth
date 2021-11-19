require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType

  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.stances = config.getParameter("stances")

  activeItem.setCursor("/cursors/reticle0.cursor")
  self.weapon:setStance(self.stances.idle)

  -- Orbitals
  self.magnorbTimer = 0.25
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  self.cooldownTime = config.getParameter("cooldownTime", 0)
  self.cooldownTimer = self.cooldownTime

  -- Trust me, it just works
  storage.projectileIds = storage.projectileIds or {false, false, false, false, false, false, false, false}
  storage.projectilesAvailable = storage.projectilesAvailable or {true, true, true, true, false, false, false, false}

  self:checkProjectiles()
  self.orbitRate = config.getParameter("orbitRate", 1) * -2 * math.pi
  animator.resetTransformationGroup("orbs")
  for i = 1,8 do
    animator.setAnimationState("orb"..i, (storage.projectileIds[i] == false and storage.projectilesAvailable[i]) and "orb" or "hidden")
  end
  self:setOrbPosition(0.75)
  -- End

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self:checkProjectiles()
  self.shiftHeld = shiftHeld

  world.debugPoint(self:focusPosition(), "blue")

  if (self.fireMode == (self.activatingFireMode or self.abilitySlot))
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy")
    and not (self.shiftHeld and self:availableAdditionalOrbs() == 0) then
      self:setState(self.fire)
  end

  if self.fireMode == "alt" and self.lastFireMode ~= "alt"
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy") then

    if self.shiftHeld then
      self:setState(self.fire, 0)
    elseif self:availableAdditionalOrbs() < 4 then
      self:setState(self.charge)
    end
  end

  self.lastFireMode = fireMode
  self.magnorbTimer = math.max(self.magnorbTimer - dt, 0)

  animator.resetTransformationGroup("orbs")
  animator.rotateTransformationGroup("orbs", -self.weapon.aimAngle or 0)
  animator.translateTransformationGroup("orbs", {0, 2.5})

  for i = 1,4 do
    animator.rotateTransformationGroup("orb"..i, self.orbitRate * dt)
    animator.setAnimationState("orb"..i, (storage.projectileIds[i] == false and storage.projectilesAvailable[i]) and "orb" or "hidden")
  end
  for i = 5,8 do
    animator.rotateTransformationGroup("orb"..i, -self.orbitRate * dt)
    animator.setAnimationState("orb"..i, (storage.projectileIds[i] == false and storage.projectilesAvailable[i]) and "orb" or "hidden")
  end
end

function ControlProjectile:charge()
  self.weapon:setStance(self.stances.charge)

  animator.playSound(self.elementalType.."charge")
  --animator.setAnimationState("charge", "charge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  activeItem.setCursor("/cursors/charge2.cursor")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == "alt" do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."charge")

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

  self.magnorbTimer = 0
  local targetValid
  local orbIndex = 5
  while self.fireMode == "alt" and orbIndex < 9 do
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
    if storage.projectilesAvailable[orbIndex] then
      orbIndex = orbIndex + 1
    elseif self.magnorbTimer == 0 then
      storage.projectilesAvailable[orbIndex] = true
      self.magnorbTimer = 1
      animator.playSound(self.elementalType.."activate")
      self:setAdditionalOrbPosition()
      orbIndex = orbIndex + 1
    end
  end

  util.wait(0.5)

  self:setState(self.discharge)
end

function ControlProjectile:discharge()
  self.weapon:setStance(self.stances.discharge)

  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.playSound(self.elementalType.."discharge")
  self:setState(self.cooldown)
end

function ControlProjectile:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon.aimAngle = 0

  --animator.setAnimationState("charge", "discharge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function ControlProjectile:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not world.lineTileCollision(focusPos, aimPos)
end

function ControlProjectile:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

function ControlProjectile:availableAdditionalOrbs()
  count = 0
  for i=5,8 do
    if storage.projectilesAvailable[i] then count = count + 1 end
  end
  return count
end

function ControlProjectile:reset()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function ControlProjectile:uninit(weaponUninit)
  if weaponUninit then
    storage.projectilesAvailable = {true, true, true, true, false, false, false, false}
  end
  self:reset()
end

function ControlProjectile:nextOrb(start)
  for i = start,8 do
    if not storage.projectileIds[i] and storage.projectilesAvailable[i] then
      return i
    end
  end
end

function ControlProjectile:fire(timer)
  self.weapon:setStance(self.stances.fire)
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()

  local magnorbTimer = timer or self.stances.fire.duration

  while self.fireMode == "primary" or (self.fireMode == "alt" and self.shiftHeld) or magnorbTimer > 0 do
    local orbIndex = self:nextOrb((self.shiftHeld and self:availableAdditionalOrbs() > 0) and 5 or 1)
    if orbIndex then
      local firePos = self:orbFirePosition(orbIndex)
      if magnorbTimer == 0 and orbIndex and not world.lineCollision(mcontroller.position(), firePos) and status.overConsumeResource("energy", (self.fireMode == "alt" and self.shiftHeld) and 10 or 5) then
        local projectileId = world.spawnProjectile(
            orbIndex < 5 and self.projectileType or "ivrpg_primednovacrystal",
            self:orbFirePosition(orbIndex),
            activeItem.ownerEntityId(),
            self:orbAimVector(orbIndex),
            false,
            params
          )
        if projectileId then
          storage.projectileIds[orbIndex] = projectileId
          magnorbTimer = timer or self.stances.fire.duration
          animator.playSound("fire")
          if orbIndex > 4 then
            storage.projectilesAvailable[orbIndex] = false
            self:setAdditionalOrbPosition()
          end
        end
      end
    end

    magnorbTimer = math.max(0, magnorbTimer - self.dt)

    coroutine.yield()
  end

  self:setState(self.cooldown)

end

function ControlProjectile:orbFirePosition(orbIndex)
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("orb"..orbIndex, "orbPosition")))
end

function ControlProjectile:orbAimVector(orbIndex)
  return vec2.norm(world.distance(activeItem.ownerAimPosition(), self:orbFirePosition(orbIndex)))
end

function ControlProjectile:checkProjectiles()
  for i, projectileId in ipairs(storage.projectileIds) do
    if projectileId and not world.entityExists(projectileId) then
      storage.projectileIds[i] = false
    end
  end
end

function ControlProjectile:setOrbPosition(spaceFactor, distance)
  -- Base Four Orbs
  for i = 1, 4 do
    animator.resetTransformationGroup("orb"..i)
    animator.translateTransformationGroup("orb"..i, {-0.5, 0})
    animator.rotateTransformationGroup("orb"..i, 2 * math.pi * spaceFactor * ((i - 2) / 3))
  end

  -- Additional Orbs
  for i = 1, 4 do
    local x = i + 4
    animator.resetTransformationGroup("orb"..x)
    animator.translateTransformationGroup("orb"..x, {0.5, 0})
    animator.rotateTransformationGroup("orb"..x, 2 * math.pi * spaceFactor * ((i - 2) / 3) + math.pi / 4)
  end
end

function ControlProjectile:setAdditionalOrbPosition(spaceFactor, distance)
  local factors = {1, 1.5, 1, 0.75}
  local spaceFactor = self:availableAdditionalOrbs()
  if spaceFactor > 0 then
    spaceFactor = factors[spaceFactor]
  end
  -- Additional Orbs
  for i = 1, 4 do
    local x = i + 4
    animator.resetTransformationGroup("orb"..x)
    animator.translateTransformationGroup("orb"..x, {0.5, 0})
    animator.rotateTransformationGroup("orb"..x, 2 * math.pi * spaceFactor * ((i - 2) / 3) + math.pi / 4)
  end
end