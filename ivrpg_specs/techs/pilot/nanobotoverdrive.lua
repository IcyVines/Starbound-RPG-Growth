require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"
require "/tech/explorertech/explorerenhancedjump/explorerenhancedjump.lua"

oldInit = init
oldUpdate = update
oldUninit = uninit

function init()
  initCommonParameters()
  oldInit()
end

function initCommonParameters()
  self.angularVelocity = 0
  self.angle = 0
  self.transformFadeTimer = 0

  self.energyCost = config.getParameter("energyCost")
  self.ballRadius = config.getParameter("ballRadius")
  self.ballFrames = config.getParameter("ballFrames")
  self.ballSpeed = config.getParameter("ballSpeed")
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.transformedMovementParameters = config.getParameter("jetMovementParameters", {})
  self.transformedMovementParameters.collisionPoly = config.getParameter("jetCollisionPoly")
  self.transformedMovementParameters.runSpeed = self.ballSpeed
  self.transformedMovementParameters.walkSpeed = self.ballSpeed
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}

  self.facingDirection = mcontroller.facingDirection()

  self.forceDeactivateTime = config.getParameter("forceDeactivateTime", 3.0)
  self.forceShakeMagnitude = config.getParameter("forceShakeMagnitude", 0.125)

  self.cooldownTimer = 0
  self.altCooldownTimer = 0

  Bind.create("primaryFire", primaryFire, true)
  Bind.create("altFire", altFire, true)
end

function uninit()
  oldUninit()
  storePosition()
  deactivate()
end

function update(args)
  restoreStoredPosition()

  oldUpdate(args)

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.downHeld = args.moves["down"]
  self.hDirection = (args.moves["left"] == args.moves["right"]) and 0 or (args.moves["right"] and 1 or -1)
  self.vDirection = (args.moves["up"] == self.downHeld) and 0 or (self.downHeld and -1 or 1)

  if not self.specialLast and args.moves["special3"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special3"]

  if not args.moves["special3"] then
    self.forceTimer = nil
  end

  if self.transformActive then
    mcontroller.controlParameters(self.transformedMovementParameters)
    --status.setResourcePercentage("energyRegenBlock", 1.0)

    updateFrame(args.dt)

    checkForceDeactivate(args.dt)

    if self.altCooldownTimer > 0.8 then
      mcontroller.setXVelocity(self.dashActive * 150)
    elseif self.dashActive then
      mcontroller.setXVelocity(self.dashActive * 30)
      self.dashActive = false
    end
  end

  local facingDirection = world.distance(tech.aimPosition(), mcontroller.position())[1] > 0 and 1 or -1
  if facingDirection == 1 then
    animator.setFlipped(false)
    self.facingDirection = 1
  elseif facingDirection == -1 then
    animator.setFlipped(true)
    self.facingDirection = -1
  end
  --self.facingDirection = facingDirection

  self.cooldownTimer = math.max(self.cooldownTimer - self.dt, 0)
  self.altCooldownTimer = math.max(self.altCooldownTimer - self.dt, 0)

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function updateFrame(dt)

  if self.transformActive then
    animator.setLightActive("jetGlow", true)
    self.speedModifier = 1
    mcontroller.controlApproachVelocity(vec2.mul({self.hDirection, self.vDirection}, self.transformedMovementParameters.flySpeed * self.speedModifier), 150 * self.speedModifier)
    
    if self.hDirection ~= 0 then
      animator.setAnimationState("jetFHState", "activated")
      self.wasMoving = true
    elseif self.wasMoving then
      animator.setAnimationState("jetFHState", "deactivating")
      self.wasMoving = false
    end

    if self.vDirection == 1 then
      animator.setAnimationState("jetFVState", "activated")
      self.wasActive = true
    elseif self.wasActive then
      animator.setAnimationState("jetFVState", "deactivating")
      self.wasActive = false
    --elseif mcontroller.running() and mcontroller.onGround()  then
      --animator.setAnimationState("jetFState", "run")
    --elseif mcontroller.crouching() and mcontroller.onGround()  then
      --animator.setAnimationState("jetFState", "crouch")
    --elseif not self.whistling and mcontroller.onGround() then
      --animator.setAnimationState("jetFState", "idle")
    end
  end
end

function primaryFire()
  if self.transformActive and self.cooldownTimer == 0 and status.overConsumeResource("energy", 10) then
    local position = mcontroller.position()
    position[1] = position[1] + self.facingDirection * 2
    position[2] = position[2] - 2.75
    local aimDirection = world.distance(tech.aimPosition(), position)
    local aimAngle = vec2.angle(aimDirection)
    if self.facingDirection == 1 then
      if aimAngle > math.pi * 0.25 and aimAngle < math.pi then
        aimDirection = vec2.rotate({1,0}, math.pi / 4)
      elseif aimAngle < math.pi * 1.5 and aimAngle >= math.pi then
        aimDirection = vec2.rotate({1,0}, math.pi * 1.5)
      end
    elseif self.facingDirection == -1 then
      if aimAngle < math.pi * 0.75 and aimAngle >= 0 then
        aimDirection = vec2.rotate({-1,0}, -math.pi / 4)
      elseif aimAngle > math.pi * 1.5 and aimAngle <= 2 * math.pi then
        aimDirection = vec2.rotate({-1,0}, math.pi / 2)
      end
    end
    animator.playSound("fire")
    world.spawnProjectile("ivrpg_pilotjetbullet", position, entity.id(), aimDirection, false, {speed = 200, powerMultiplier = status.stat("powerMultiplier"), power = status.statusProperty("ivrpgvigor")})
    self.cooldownTimer = 0.2
  end
end

function altFire()
  if self.transformActive and self.altCooldownTimer == 0 and status.overConsumeResource("energy", 30) then
    self.altCooldownTimer = 1
    animator.setAnimationState("jetFHState", "dash")
    animator.playSound("thrust")
    self.dashActive = self.facingDirection
  end
end


-- Transformation Functions

function attemptActivation()
  if not self.transformActive
      and not tech.parentLounging()
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.energyCost) then

    local pos = transformPosition()
    if pos then
      mcontroller.setPosition(pos)
      activate()
    end
  elseif self.transformActive then
    local pos = restorePosition()
    if pos then
      mcontroller.setPosition(pos)
      deactivate()
    elseif not self.forceTimer then
      animator.playSound("forceDeactivate", -1)
      self.forceTimer = 0
    end
  end
end

function checkForceDeactivate(dt)
  animator.resetTransformationGroup("transform")

  if self.forceTimer then
    self.forceTimer = self.forceTimer + dt
    mcontroller.controlModifiers({
      movementSuppressed = true
    })

    local shake = vec2.mul(vec2.withAngle((math.random() * math.pi * 2), self.forceShakeMagnitude), self.forceTimer / self.forceDeactivateTime)
    animator.translateTransformationGroup("transform", shake)
    if self.forceTimer >= self.forceDeactivateTime then
      deactivate()
      self.forceTimer = nil
    else
      attemptActivation()
    end
    return true
  else
    animator.stopAllSounds("forceDeactivate")
    return false
  end
end

function storePosition()
  if self.transformActive then
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
    animator.setGlobalTag("ballDirectives", string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  elseif self.transformFadeTimer < 0 then
    self.transformFadeTimer = math.min(0, self.transformFadeTimer + dt)
    tech.setParentDirectives(string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("ballDirectives", "")
    tech.setParentDirectives()
  end
end

function positionOffset()
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
  if not self.transformActive then
    animator.burstParticleEmitter("activateParticles")
    animator.playSound("transformActivate")
    animator.setAnimationState("jetState", "idle")
    animator.setAnimationState("jetFVState", "deactivated")
    animator.setAnimationState("jetFHState", "deactivated")
    self.angularVelocity = 0
    self.angle = 0
    self.transformFadeTimer = self.transformFadeTime
  end
  tech.setParentHidden(true)
  tech.setParentOffset({0, positionOffset()})
  tech.setToolUsageSuppressed(true)
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  self.transformActive = true
end

function deactivate()
  if self.transformActive then
    animator.burstParticleEmitter("deactivateParticles")
    animator.playSound("deactivate")
    animator.setAnimationState("jetState", "off")
    animator.setAnimationState("jetFVState", "off")
    animator.setAnimationState("jetFHState", "off")
    self.transformFadeTimer = -self.transformFadeTime
  else
    animator.setAnimationState("jetState", "off")
    animator.setAnimationState("jetFHState", "off")
    animator.setAnimationState("jetFVState", "off")
  end
  animator.stopAllSounds("forceDeactivate")
  animator.setGlobalTag("ballDirectives", "")
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  self.angle = 0
  self.transformActive = false
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
