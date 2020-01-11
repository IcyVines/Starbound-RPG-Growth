require "/items/active/protectorate/wands/controlprojectile.lua"

function ControlProjectile:charged()
  self.weapon:setStance(self.stances.charged)

  animator.playSound(self.elementalType.."fullcharge")
  animator.playSound(self.elementalType.."chargedloop", -1)
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)

  self.projectileSpawnTimer = 0

  local targetValid
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and not status.resourceLocked("energy") do
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

    mcontroller.controlModifiers({runningSuppressed = true})

    status.setResourcePercentage("energyRegenBlock", 1.0)

    self.lastPosition = mcontroller.position()

    self.projectileSpawnTimer = math.max(0, self.projectileSpawnTimer - self.dt)
    if self.projectileSpawnTimer == 0 and targetValid then
      local energyCon = vec2.mag(world.distance(self.lastPosition, activeItem.ownerAimPosition()))
      if status.overConsumeResource("energy", self.energyPerShot * util.clamp(energyCon / 10, 0.5, 3)) then
        self:createProjectiles()
        self.lastPosition = activeItem.ownerAimPosition()
        if #storage.projectiles > 1 then
          local delayTime = self.projectileDelayEach
          local projectileId = storage.projectiles[1]
          if world.entityExists(projectileId) then
            world.sendEntityMessage(projectileId, "trigger", delayTime, activeItem.ownerAimPosition())
            delayTime = delayTime + self.projectileDelayEach
          end
          table.remove(storage.projectiles, 1)
        end
        self.projectileSpawnTimer = self.projectileSpawnInterval
      end
    end

    coroutine.yield()
  end

  self:setState(self.discharge)
end


function ControlProjectile:discharge()
  self.weapon:setStance(self.stances.discharge)

  activeItem.setCursor("/cursors/reticle0.cursor")

  if #storage.projectiles > 0 then
    local delayTime = self.projectileDelayEach
    for _, projectileId in pairs(storage.projectiles) do
      if world.entityExists(projectileId) then
        local energyCon = vec2.mag(world.distance(self.lastPosition, activeItem.ownerAimPosition()))
        status.overConsumeResource("energy", self.energyPerShot * util.clamp(energyCon / 10, 0.5, 3))
        world.sendEntityMessage(projectileId, "trigger", delayTime, activeItem.ownerAimPosition())
        delayTime = delayTime + self.projectileDelayEach
      end
    end
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
    return
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
