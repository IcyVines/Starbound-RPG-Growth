require "/scripts/vec2.lua"

function initCommonParameters()
  self.transformFadeTimer = 0
  self.directives = ""
  self.creature = false
  self.oldCreature = false
  self.oldPoly = false
  self.damageUpdate = 5
  self.melty = false

  -- Shared Vars
  self.fireTimer = 0
  self.chargeFire = false
  self.fireCooldownTimer = 0.5
  self.frameCooldownTimer = 0
  self.altFrameCooldownTimer = 0
  self.hueShift = 0
  self.soundActive = false
  self.speedModifier = 1
  self.hurtTimer = 0
  self.transformedStats = {}
  self.damageGivenUpdate = 5
  --Giant Vars
  self.giantCounter = 0
  self.flashTimer = 0
  self.giantAvailable = false
  self.giant = false
  self.giantTransform = false
  self.giantHitbox = false
  self.giantTimer = 0
  -- Poptop Vars
  self.roarTimer = 0
  self.devouring = false
  self.bloodlust = 0
  self.whistling = false
  self.whistlingTimer = 0
  self.roaringTimer = 0
  self.roaringCooldownTimer = 0
  -- Wisper Vars
  self.idleTimer = 0
  self.wisperExplosion = false
  -- Orbide Vars
  self.crouchTimer = 0
  self.getupTimer = 0
  self.grit = 0
  self.invulnerable = false
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
  self.transformedMovementParameters = config.getParameter((self.creature or "giant") .. "MovementParameters")
  local collisionPoly = self.giantTransform and self.transformedMovementParameters.collisionPoly or config.getParameter(self.creature .. (self.melty and "MeltyCollisionPoly" or  "CollisionPoly"))
  self.transformedMovementParameters.collisionPoly = collisionPoly

  if not tech.parentLounging()
      and not (status.statPositive("activeMovementAbilities") and not status.statPositive("ivrpgshapeshifting"))
      and not shiftBack then

    local pos = transformPosition()

    if self.giantTransform then
      if pos then 
        mcontroller.setPosition(pos or mcontroller.position())
        self.giantAvailable = false
        self.giantCounter = 0
        self.giantTimer = 10
        deactivate()
      else
        reset()
      end
      self.giantTransform = false
    elseif (pos or self.creature == 'wisper') and status.overConsumeResource("energy", self.energyCost / 4) then
      mcontroller.setPosition(pos or mcontroller.position())
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

function checkHurtFrame()
  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.healthLost > 0 then
        self.hurtTimer = 0.1
      end
    end
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
    local collisionPoly = config.getParameter(self.creature .. (self.melty and "MeltyCollisionPoly" or  "CollisionPoly"))
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
  local faceOnly = self.chargeFire or self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0
  animator.setFlipped(mcontroller.facingDirection() == -1 or (not mcontroller.movingDirection() == 1 and not faceOnly))
  if faceOnly then
    if (self.creature == "orbide" or self.creature == "poptop" or self.creature == "adultpoptop") and self.frameCooldownTimer > 0 and self.frameCooldownTimer <= 0.1 then
      animator.setAnimationState(self.creature .. "State", "chargewinddown")
    end
    return
  end
  if self.creature == "poptop" then
    self.hueShift = 180
    if mcontroller.jumping() then
      animator.setAnimationState(self.creature .. "State", "jump")
    elseif mcontroller.falling() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif (mcontroller.walking() or self.whistling) and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", self.whistling and "stroll" or "walk")
    elseif mcontroller.running() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "run")
    elseif mcontroller.crouching() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "crouch")
    elseif not self.whistling and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "idle")
    end
  elseif self.creature == "adultpoptop" then
    self.hueShift = 180
    if self.roaringTimer > 0 then
      animator.setAnimationState(self.creature .. "State", "roar")
      suppressMovement()
    elseif mcontroller.jumping() then
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
  elseif self.creature == "wisper" then
    self.hueShift = 90
    animator.setLightActive("wisperGlow", true)
    mcontroller.controlApproachVelocity(vec2.mul({self.hDirection, self.vDirection}, self.transformedMovementParameters.flySpeed * self.speedModifier), 5 * self.speedModifier)
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
    animator.setAnimationRate(1)
    if self.crouchTimer > 0 then
      animator.setAnimationState(self.creature .. "State", "invulnerablewindup")
      self.crouchTimer = math.max(self.crouchTimer - dt, 0)
      if self.crouchTimer == 0 then
        self.invulnerable = true
      end
      suppressMovement()
    elseif self.invulnerable then
      animator.setAnimationState(self.creature .. "State", "invulnerable")
      status.addEphemeralEffect("regeneration2", 0.1, self.id)
      suppressMovement()
    elseif self.getupTimer > 0 then
      animator.setAnimationState(self.creature .. "State", "invulnerablewinddown")
      self.getupTimer = math.max(self.getupTimer - dt, 0)
      suppressMovement()
    elseif mcontroller.jumping() then
      animator.setAnimationState(self.creature .. "State", "jump")
    elseif mcontroller.falling() then
      animator.setAnimationState(self.creature .. "State", "fall")
    elseif mcontroller.running() and mcontroller.onGround()  then
      animator.setAnimationState(self.creature .. "State", "walk")
      animator.setAnimationRate(self.speedModifier)
    elseif mcontroller.walking() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "walk")
      animator.setAnimationRate(math.max(self.speedModifier/2, 1))
    elseif mcontroller.crouching() and mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "crouch")
    elseif mcontroller.onGround() then
      animator.setAnimationState(self.creature .. "State", "idle")
    end
  end
  checkHurtFrame()
  if self.hurtTimer > 0 and not (self.crouchTimer > 0 or self.getupTimer > 0) then
    if self.creature == "wisper" then
      mcontroller.controlApproachVelocity({0,0}, 150)
    end
    animator.setAnimationState(self.creature .. "State", "hurt")
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
  self.giant = false
  self.fireTimer = 0
  self.chargeFire = false
  self.invulnerable = false
  self.getupTimer = 0
  self.crouchTimer = 0
  self.transformedStats = config.getParameter(self.creature .. "Stats", {})
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
  self.giant = self.giantTransform
  if self.active then
    animator.burstParticleEmitter("deactivateParticles")
    animator.playSound("deactivate")
    self.transformFadeTimer = -self.transformFadeTime
  elseif self.giant then
    animator.burstParticleEmitter("activateParticles")
    animator.playSound("activate")
    self.transformFadeTimer = -self.transformFadeTime
  end
  animator.setAnimationState("poptopState", "off")
  animator.setAnimationState("wisperState", "off")
  animator.setAnimationState("orbideState", "off")
  animator.setAnimationState("adultpoptopState", "off")
  animator.stopAllSounds("forceDeactivate")
  status.setStatusProperty("ivrpgshapeshiftC", self.giant and "giant" or "")
  animator.setGlobalTag("directives", self.directives)
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setParentState()
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  self.transformedMovementParameters = {}
  self.transformedStats = {}
  self.fireTimer = 0
  self.invulnerable = false
  self.getupTimer = 0
  self.crouchTimer = 0
  self.chargeFire = false
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
