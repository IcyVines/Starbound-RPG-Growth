require "/scripts/vec2.lua"

function initCommonParameters()
  self.transformFadeTimer = 0
  self.directives = ""
  self.creature = false
  self.oldCreature = false
  self.oldPoly = false
  self.hueShift = 0

  -- Poptop Vars
  self.strollTimer = 0
  -- Wisper Vars
  self.idleTimer = 0
  -- Orbide Vars
  self.crouchTimer = 0
  -- Bone Vars

  self.energyCost = config.getParameter("energyCost")
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.transformedMovementParameters = {}
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}

  self.forceDeactivateTime = config.getParameter("forceDeactivateTime", 3.0)
  self.forceShakeMagnitude = config.getParameter("forceShakeMagnitude", 0.125)
end

function attemptActivation(shiftBack)
  self.oldPoly = (not shiftBack) and self.transformedMovementParameters.collisionPoly or false
  self.transformedMovementParameters = config.getParameter(self.creature .. "MovementParameters")
  local collisionPoly = config.getParameter(self.creature .. (status.statPositive("ivrpgmeltyblood") and "MeltyCollisionPoly" or  "CollisionPoly"))
  self.transformedMovementParameters.collisionPoly = collisionPoly

  if not tech.parentLounging()
      and not (status.statPositive("activeMovementAbilities") and not status.statPositive("ivrpgshapeshifting"))
      and not shiftBack then

    local pos = transformPosition()
    if pos and status.overConsumeResource("energy", self.energyCost) then
      mcontroller.setPosition(pos)
      activate()
    else
      reset()
    end
  elseif self.active and shiftBack then
    local pos = restorePosition()
    if pos then
      mcontroller.setPosition(pos)
      deactivate()
    elseif not self.forceTimer then
      animator.playSound("forceDeactivate", -1)
      self.forceTimer = 0
    end
  else
    reset()
  end
end

function checkForceDeactivate(dt)
  animator.resetTransformationGroup("monster")

  if self.forceTimer then
    self.forceTimer = self.forceTimer + dt
    mcontroller.controlModifiers({
      movementSuppressed = true
    })

    local shake = vec2.mul(vec2.withAngle((math.random() * math.pi * 2), self.forceShakeMagnitude), self.forceTimer / self.forceDeactivateTime)
    animator.translateTransformationGroup("monster", shake)
    if self.forceTimer >= self.forceDeactivateTime then
      deactivate()
      self.forceTimer = nil
    else
      attemptActivation(true)
    end
    return true
  else
    animator.stopAllSounds("forceDeactivate")
    return false
  end
end

function reset()
  self.creature = self.oldCreature
  self.oldPoly = false
  if self.creature then
    self.transformedMovementParameters = config.getParameter(self.creature .. "MovementParameters")
    local collisionPoly = config.getParameter(self.creature .. (status.statPositive("ivrpgmeltyblood") and "MeltyCollisionPoly" or  "CollisionPoly"))
    self.transformedMovementParameters.collisionPoly = collisionPoly
  end
end

function storePosition()
  if self.active then
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

function updateFrame(dt)
  if self.creature == "poptop" then
    self.hueShift = 180
    if mcontroller.jumping() then
      animator.setAnimationState(self.creature .. "State", "jump")
    elseif mcontroller.falling() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif mcontroller.running() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "run")
    elseif mcontroller.walking() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "stroll")
      self.strollTimer = 0.1
    elseif mcontroller.crouching() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "crouch")
    elseif self.strollTimer == 0 and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "idle")
    end
    self.strollTimer = math.max(self.strollTimer - dt, 0)
  elseif self.creature == "adultpoptop" then
    self.hueShift = 180
    if mcontroller.jumping() then
      animator.setAnimationState(self.creature .. "State", "jump")
    elseif mcontroller.falling() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif mcontroller.running() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "walk")
    elseif mcontroller.walking() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "walk")
    elseif mcontroller.crouching() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "idle")
    end
  elseif self.creature == "wisper" then
    self.hueShift = 90
    animator.setLightActive("wisperGlow", true)
    mcontroller.controlApproachVelocity(vec2.mul({self.hDirection, self.vDirection}, self.transformedMovementParameters.flySpeed), 5)
    if not mcontroller.flying() then
      animator.setAnimationState(self.creature .. "State", "idle")
      self.idleTimer = 0.1
    elseif self.idleTimer == 0 then
      animator.setAnimationState(self.creature .. "State", "fly")
    end
    self.idleTimer = math.max(self.idleTimer - dt, 0)
  elseif self.creature == "orbide" then
    self.hueShift = -240
    animator.setLightActive("orbideGlow", true)
    if mcontroller.jumping() then
      animator.setAnimationState(self.creature .. "State", "jump")
    elseif mcontroller.falling() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif mcontroller.running() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "walk")
    elseif mcontroller.walking() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "walk")
    elseif mcontroller.crouching() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "crouch")
    elseif mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "idle")
    end
  end
  animator.setFlipped(mcontroller.facingDirection() == -1 or mcontroller.movingDirection() == -1)
end

function updateTransformFade(dt)
  if self.transformFadeTimer > 0 then
    self.transformFadeTimer = math.max(0, self.transformFadeTimer - dt)
    animator.setGlobalTag("directives", string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, self.transformFadeTimer / (self.transformFadeTime - 0.15))) .. self.directives)
  elseif self.transformFadeTimer < 0 then
    self.transformFadeTimer = math.min(0, self.transformFadeTimer + dt)
    tech.setParentDirectives(string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("directives", self.directives)
    tech.setParentDirectives()
  end
end

function positionOffset()
  return minY(self.transformedMovementParameters.collisionPoly) - minY(self.oldPoly or self.basePoly)
end

function positionOffset2()
  return minY(self.transformedMovementParameters.collisionPoly) - minY(self.basePoly)
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

function activate()
  animator.burstParticleEmitter("activateParticles")
  animator.playSound("activate")
  self.transformFadeTimer = self.transformFadeTime
  animator.setAnimationState(self.creature .. "State", "idle")
  if self.oldCreature then
    animator.setAnimationState(self.oldCreature .. "State", "off")
  end
  status.setStatusProperty("ivrpgshapeshiftC", self.creature)
  animator.setLightActive("wisperGlow", false)
  animator.setLightActive("orbideGlow", false)
  tech.setParentHidden(true)
  tech.setParentOffset({0, positionOffset2()})
  tech.setToolUsageSuppressed(true)
  status.setPersistentEffects("movementAbility", {
    {stat = "activeMovementAbilities", amount = 1},
    {stat = "ivrpgshapeshifting", amount = 1}
  })
  self.active = true
end

function deactivate()
  if self.active then
    animator.burstParticleEmitter("deactivateParticles")
    animator.playSound("deactivate")
    self.transformFadeTimer = -self.transformFadeTime
  end
  animator.setAnimationState("poptopState", "off")
  animator.setAnimationState("wisperState", "off")
  animator.setAnimationState("orbideState", "off")
  animator.setAnimationState("adultpoptopState", "off")
  animator.stopAllSounds("forceDeactivate")
  status.setStatusProperty("ivrpgshapeshiftC", "")
  animator.setGlobalTag("directives", self.directives)
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  self.transformedMovementParameters = {}
  self.active = false
  self.oldCreature = false
  self.creature = false
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
