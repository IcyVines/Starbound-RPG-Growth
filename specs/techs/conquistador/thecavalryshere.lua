require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.energyCost = config.getParameter("energyCost")

  self.cooldownTime = config.getParameter("cooldownTime")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=b79d5bFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0

  
  self.id = entity.id()
  self.mounted = false

  self.airTime = 0.3
  self.airTimer = 0

  self.transformFadeTimer = 0
  self.directives = ""
  self.flashTimer = 0
  self.landingSound = false

  self.regenTimer = 0
  self.regenTime = 5

  self.directives = ""

  self.damageUpdate = 5
  self.damageGivenUpdate = 5

  self.maxMountHealth = status.resourceMax("health") * 3
  self.mountHealth = self.maxMountHealth

  self.transformedStats = config.getParameter("mountStats", {})
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.transformedMovementParameters = config.getParameter("mountMovementParameters", {})
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}

  Bind.create("g", mount)
  Bind.create("jumping", jump)
end

function mount()
  if self.mounted then
    attemptActivation(true)
  else
    attemptActivation(false)
  end
end

function jump()
  if self.mounted and mcontroller.canJump() then
    animator.playSound("mount_jump")
  end
end

function attemptActivation(shiftBack)
  if not tech.parentLounging()
      and not status.statPositive("activeMovementAbilities")
      and not shiftBack then

    local pos = transformPosition()

    if pos and status.overConsumeResource("energy", self.energyCost / 4) then
      mcontroller.setPosition(pos or mcontroller.position())
      activate()
    end
  elseif self.mounted and shiftBack then
    local pos = restorePosition()
    if pos then
      mcontroller.setPosition(pos)
      deactivate()
    end
  end
end

function activate()
  animator.playSound("activate")
  animator.playSound("mount_snort")
  self.transformFadeTimer = self.transformFadeTime
  animator.setAnimationState("mount", "idle")
  --tech.setParentOffset({0, positionOffset()})
  status.setPersistentEffects("movementAbility", {
    {stat = "activeMovementAbilities", amount = 1},
    {stat = "ivrpgmounted", amount = 1}
  })
  self.mounted = true
end

function deactivate()
  if self.mounted then
    animator.playSound("deactivate")
    animator.playSound("mount_hurt")
  end
  self.transformFadeTimer = -self.transformFadeTime
  animator.setAnimationState("mount", "off")
  animator.setGlobalTag("directives", self.directives)
  --tech.setParentOffset({0, 0})
  tech.setParentState()
  status.clearPersistentEffects("movementAbility")
  status.clearPersistentEffects("ivrpgthecavalryshere")
  self.mounted = false
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageSourceKind == "rushelectricplasma" then
        if notification.healthLost > 0 and notification.damageDealt > notification.healthLost then
          status.modifyResourcePercentage("energy", 0.2)
          status.setResourceLocked("energy", false)
        end
      end
    end
  end
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 and self.mounted then
        local damageDealt = notification.healthLost
        if notification.damageSourceKind
          and (notification.damageSourceKind == "falling"
          or notification.damageSourceKind == "poison"
          or notification.damageSourceKind == "fire")
          then
            -- These Damage Types 
            damageDealt = damageDealt / 2
        end
        self.mountHealth = math.max(self.mountHealth - damageDealt, 0)
        status.modifyResource("health", damageDealt)
      end
    end
  end
end

function update(args)
  --updateDamageGiven()

  restoreStoredPosition()

  updateDamageTaken()

  calculateHealthTags()
  animator.setAnimationState("health", self.mountHealth == self.maxMountHealth and "off" or "on")
  local isInLiquid = isInLiquid()

  self.maxMountHealth = status.resourceMax("health") * 2

  if self.flashTimer > 0 then self.directives = self.directives .. "?fade=FFEEFF=" .. self.flashTimer end

  if self.mounted then
    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setPersistentEffects("ivrpgthecavalryshere", self.transformedStats)
    tech.setParentState("Sit")
    animator.setFlipped(mcontroller.facingDirection() == -1)
    animator.setGlobalTag("health_flip", mcontroller.facingDirection() == -1 and "?flipx" or "")

    if self.mountHealth == 0 then
      deactivate()
      self.regenTimer = self.regenTime
    end

    if mcontroller.jumping() or (mcontroller.falling() or not mcontroller.onGround()) and not isInLiquid then
      self.airTimer = self.airTimer + args.dt
      if mcontroller.facingDirection() ~= mcontroller.movingDirection() then
        mcontroller.controlModifiers({
          speedModifier = 0.25,
          airJumpModifier = 0.5
        })
      end
      if self.airTimer >= self.airTime or mcontroller.jumping() then
        animator.setAnimationState("mount", "jump")
        self.landingSound = true
      end
    elseif mcontroller.running() or mcontroller.walking() or isInLiquid then

      if self.landingSound then
        self.landingSound = false
        if not isInLiquid then
          animator.playSound("mount_land")
        end
      end

      self.airTimer = 0
      if mcontroller.facingDirection() ~= mcontroller.movingDirection() then
        if isInLiquid then
          animator.setAnimationState("mount", math.abs(mcontroller.xVelocity()) < 1 and "idle" or "swimBack")
        else
          animator.setAnimationState("mount", "runBack")
        end
        mcontroller.controlModifiers({
          speedModifier = 0.25
        })
      else
        if isInLiquid then
          animator.setAnimationState("mount", math.abs(mcontroller.xVelocity()) < 1 and "idle" or "swim")
        else
          animator.setAnimationState("mount", "swim")
        end
      end
    else
      self.airTimer = 0
      animator.setAnimationState("mount", "idle")
    end
  else
    self.regenTimer = math.max(self.regenTimer - args.dt, 0)
    if self.regenTimer == 0 then
      self.mountHealth = math.min(self.mountHealth + args.dt * 10, self.maxMountHealth)
    end
    tech.setParentState()
    animator.setAnimationState("mount", "off")
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
      self.rechargeEffectTimer = self.rechargeEffectTime
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(self.rechargeEffectTimer - args.dt, 0)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

  updateTransformFade(args.dt)
  self.flashTimer = math.max(self.flashTimer - args.dt, 0)

end

function calculateHealthTags()
  local percent = math.floor((self.mountHealth) / (self.maxMountHealth) * 50 + 0.5)
  animator.setGlobalTag("health", tostring(percent))
end

function uninit()
  self.mounted = false
  storePosition()
  deactivate()
  tech.setParentDirectives()
end

function positionOffset()
  return minY(self.transformedMovementParameters.collisionPoly) - minY(self.basePoly)
end

function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end


function transformPosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, {pos[1], pos[2] - positionOffset()}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, pos, 1, self.collisionSet)
  end
end

function restorePosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.basePoly, {pos[1], pos[2] + positionOffset()}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.basePoly, pos, 1, self.collisionSet)
  end
end

function storePosition()
  if self.mounted then
    storage.restorePosition = restorePosition()

    -- try to restore position. if techs are being switched, this will work and the storage will
    -- be cleared anyway. if the client's disconnecting, this won't work but the storage will remain to
    -- restore the position later in update()
    if storage.restorePosition then
      storage.lastActivePosition = mcontroller.position()
      mcontroller.setPosition(storage.restorePosition)
    end
  end
end

function restoreStoredPosition()
  if storage.restorePosition then
    -- restore position if the player was logged out (in the same planet/universe) with the tech active
    if vec2.mag(vec2.sub(mcontroller.position(), storage.lastActivePosition)) < 1 then
      mcontroller.setPosition(storage.restorePosition)
    end
    storage.lastActivePosition = nil
    storage.restorePosition = nil
  end
end

function updateTransformFade(dt)
  if self.transformFadeTimer > 0 then
    self.transformFadeTimer = math.max(0, self.transformFadeTimer - dt)
    animator.setGlobalTag("directives", string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, self.transformFadeTimer / (self.transformFadeTime - 0.15))) .. self.directives)
  elseif self.transformFadeTimer < 0 then
    self.transformFadeTimer = math.min(0, self.transformFadeTimer + dt)
    tech.setParentDirectives(self.directives .. string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("directives", self.directives)
    tech.setParentDirectives(self.directives)
  end
end
