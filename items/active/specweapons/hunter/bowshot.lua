require "/scripts/vec2.lua"

-- Bow primary ability
BowShot = WeaponAbility:new()

function BowShot:init()
  self.cloakParameters = config.getParameter("cloakParameters", {})
  self.energyPerShot = self.energyPerShot or 0
  self.cloakActive = false
  self.drawTime = 0
  self.cooldownTimer = self.cooldownTime
  self.cloakElement = ""
  self.drawTimeMultiplier = 1
  self:reset()

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function BowShot:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyPerShot == 0 or not status.resourceLocked("energy")) then
    self:setState(self.draw)
  elseif self.fireMode == "alt" and (not status.resourceLocked("energy")) and self.cooldownTimer == 0 and status.resource("energy") == status.stat("maxEnergy") and not self.cloakActive then
    self.cloakActive = true
    self.cloakElement = status.statusProperty("ivrpgmultitoolenergy") or ""
    if self.cloakElement == "electric" then
      world.spawnProjectile(
          "electricplasmaexplosion",
          self:firePosition(),
          activeItem.ownerEntityId(),
          {0,0},
          false,
          {power = 20, powerMultiplier = status.stat("powerMultiplier")}
        )
    end
  end

  if self.cloakActive then
    status.overConsumeResource("energy", 10 * dt)
    if status.resourceLocked("energy") or status.resource("energy") == 0 then
      self.cloakActive = false
      self.cloakElement = ""
    end
    self.energyPerShot = self.cloakParameters[self.cloakElement].energyPerShot or self.energyPerShot
    self.cooldownTime = self.cloakParameters[self.cloakElement].cooldownTime or self.cooldownTime
    self.drawTimeMultiplier = self.cloakParameters[self.cloakElement].drawTimeMultiplier or 1
    self.inaccuracy = self.cloakParameters[self.cloakElement].inaccuracy or 0
    self.projectileParameters = self.cloakParameters[self.cloakElement].projectileParameters or {}
    animator.setGlobalTag("cloakEnergy", self.cloakElement)
  end

end

function BowShot:uninit()
  self:reset()
end

function BowShot:reset()
  animator.setGlobalTag("drawFrame", "0")
  animator.setGlobalTag("cloakEnergy", self.cloakElement)
  self.weapon:setStance(self.stances.idle)
end

function BowShot:draw()
  self.weapon:setStance(self.stances.draw)

  animator.playSound("draw")

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    if self.walkWhileFiring then mcontroller.controlModifiers({runningSuppressed = true}) end

    self.drawTime = self.drawTime + (self.dt * self.drawTimeMultiplier)

    local drawFrame = math.floor(root.evalFunction(self.drawFrameSelector, self.drawTime))
    animator.setGlobalTag("drawFrame", drawFrame)
    self.stances.draw.frontArmFrame = self.drawArmFrames[drawFrame + 1]

    coroutine.yield()
  end

  self:setState(self.fire)
end

function BowShot:fire()
  self.weapon:setStance(self.stances.fire)

  animator.stopAllSounds("draw")
  animator.setGlobalTag("drawFrame", "0")

  local perfectTiming = self:perfectTiming()

  if not world.pointTileCollision(self:firePosition()) and status.overConsumeResource("energy", self.energyPerShot / (perfectTiming and 2 or 1)) then
    world.spawnProjectile(
        (perfectTiming and self.powerProjectileType or self.projectileType) .. (self.cloakActive and self.cloakElement or ""),
        self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(),
        false,
        self:currentProjectileParameters()
      )
    if self.cloakActive and self.cloakElement == "electric" then
      for i=-1,1,2 do
        world.spawnProjectile(
          (perfectTiming and self.powerProjectileType or self.projectileType) .. (self.cloakActive and self.cloakElement or ""),
          self:firePosition(),
          activeItem.ownerEntityId(),
          vec2.rotate(self:aimVector(), i*math.pi/18),
          false,
          self:currentProjectileParameters()
        )
      end
    end

    if self:perfectTiming() then
      animator.playSound("perfectRelease")
    else
      animator.playSound("release")
    end

    self.drawTime = 0

    util.wait(self.stances.fire.duration)
  else
    self.drawTime = 0
  end

  self.cooldownTimer = self.cooldownTime
end

function BowShot:perfectTiming()
  return self.drawTime > self.powerProjectileTime[1] and self.drawTime < self.powerProjectileTime[2]
end

function BowShot:currentProjectileParameters()
  local projectileParameters = copy(self.projectileParameters or {})
  local projectileConfig = root.projectileConfig(self:perfectTiming() and self.powerProjectileType or self.projectileType)
  projectileParameters.speed = projectileParameters.speed or projectileConfig.speed
  projectileParameters.speed = projectileParameters.speed * root.evalFunction(self.drawSpeedMultiplier, self.drawTime)
  projectileParameters.power = projectileParameters.power or projectileConfig.power
  projectileParameters.power = projectileParameters.power
      * self.weapon.damageLevelMultiplier
      * root.evalFunction(self.drawPowerMultiplier, self.drawTime)
  projectileParameters.powerMultiplier = activeItem.ownerPowerMultiplier()

  return projectileParameters
end

function BowShot:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * self.weapon.aimDirection
  return aimVector
end

function BowShot:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end
