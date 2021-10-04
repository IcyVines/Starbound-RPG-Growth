require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/keybinds.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  initCommonParameters()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.damageDisableTime = config.getParameter("damageDisableTime")
  self.damageDisableTimer = 0
  self.headingAngle = nil
  self.justActivatedTimer = 0
  self.magnetizeTimer = 0
  self.distance = 25
  self.beaconCooldown = 2
  self.beaconCooldownTimer = self.beaconCooldown
  self.bombTimer = 1

  self.normalCollisionSet = {"Block", "Dynamic"}
  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end

  Bind.create("f", plantBeacon)
  Bind.create("primaryFire", shootPulse)

end

function update(args)
  restoreStoredPosition()

  self.shiftHeld = not args.moves["run"]

  self.beaconCooldownTimer = math.max(self.beaconCooldownTimer - args.dt, 0)

  if not self.specialLast and args.moves["special1"] and not self.shiftHeld then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]

  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  self.damageDisableTimer = math.max(0, self.damageDisableTimer - args.dt)

  self.energyRegenBlock = status.resource("energyRegenBlock")
  self.beaconActive = status.statPositive("ivrpgoperativebeacon")
  self.bombTimer = math.max(0, self.bombTimer - args.dt)

  if self.active then

    status.setResourcePercentage("energyRegenBlock", 1.0)
    if status.resource("energy") > 10 then status.setResourceLocked("energy", false) end
    if self.beaconActive then status.modifyResource("energy", args.dt * 5) end

    local groundDirection
    if self.damageDisableTimer == 0 then
      groundDirection = findGroundDirection()
    end

    if args.moves["jump"] and self.magnetizeDirection and status.overConsumeResource("energy", args.dt * 10 * (self.beaconActive and 0.5 or 1)) then
      if self.magnetizeTimer == 0 then mcontroller.setVelocity({0,0}) end
      magnetizeTo(false)
      animator.setAnimationState("ballState", "magnetic")
      self.magnetizeTimer = math.min(self.magnetizeTimer + args.dt, 3)
    elseif groundDirection then
      if animator.animationState("ballState") == "magnetic" then
        animator.setAnimationState("ballState", "on")
        animator.playSound("latch")
        turnOffParticles(0)
        self.magnetizeTimer = 0.5
      end

      if not self.headingAngle then
        self.headingAngle = (math.atan(groundDirection[2], groundDirection[1]) + math.pi / 2) % (math.pi * 2)
      end

      self.magnetizeTimer = math.max(self.magnetizeTimer - args.dt, 0)
      self.magnetizeDirection = nil
      if args.moves["jump"] and self.magnetizeTimer == 0 then
        findMagnetizePos(groundDirection)
      end

      local moveX = 0
      if args.moves["right"] then moveX = moveX + 1 end
      if args.moves["left"] then moveX = moveX - 1 end
      if moveX ~= 0 then
        -- find any collisions in the moving direction, and adjust heading angle *up* until there is no collision
        -- this makes the heading direction follow concave corners

        --consume energy only when moving
        --status.setResourcePercentage("energyRegenBlock", 1.0)
        
        
        local adjustment = 0
        for a = 0, math.pi, math.pi / 4 do
          local testPos = vec2.add(mcontroller.position(), vec2.rotate({moveX * 0.25, 0}, self.headingAngle + (moveX * a)))
          adjustment = moveX * a
          if not world.polyCollision(poly.translate(poly.scale(mcontroller.collisionPoly(), 1.0), testPos), nil, self.normalCollisionSet) then
            break
          end
        end
        self.headingAngle = self.headingAngle + adjustment

        -- find empty space in the moving direction and adjust heading angle *down* until it collides
        -- adjust to the angle *before* the collision occurs
        -- this makes the heading direction follow convex corners
        adjustment = 0
        for a = 0, -math.pi, -math.pi / 4 do
          local testPos = vec2.add(mcontroller.position(), vec2.rotate({moveX * 0.25, 0}, self.headingAngle + (moveX * a)))
          if world.polyCollision(poly.translate(poly.scale(mcontroller.collisionPoly(), 1.0), testPos), nil, self.normalCollisionSet) then
            break
          end
          adjustment = moveX * a
        end
        self.headingAngle = self.headingAngle + adjustment

        -- apply a gravitation like force in the ground direction, while moving in the controlled direction
        -- Note: this ground force causes weird collision when moving up slopes, result is you move faster up slopes
        local groundAngle = self.headingAngle - (math.pi / 2)
        mcontroller.controlApproachVelocity(vec2.withAngle(groundAngle, self.ballSpeed), 3800)

        local moveDirection = vec2.rotate({moveX, 0}, self.headingAngle)
        mcontroller.controlApproachVelocityAlongAngle(math.atan(moveDirection[2], moveDirection[1]), self.ballSpeed, 2000)
        self.angularVelocity = -moveX * self.ballSpeed
      else
        --status.overConsumeResource("energy", 0)
        --status.setResource("energyRegenBlock", self.energyRegenBlock)
        --status.consumeResource("health", self.healthCostPerSecond * args.dt)
        mcontroller.controlApproachVelocity({0,0}, 2000)
        self.angularVelocity = 0
      end

      mcontroller.controlDown()

      status.setResourcePercentage("energyRegenBlock", 1.0)
      updateAngularVelocity(args.dt)

      self.transformedMovementParameters.gravityEnabled = false
    elseif self.magnetizeDirection then
      magnetizeTo(true)
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
    end

    mcontroller.controlParameters(self.transformedMovementParameters)

    updateRotationFrame(args.dt)

    checkForceDeactivate(args.dt)

  else
    self.headingAngle = nil
    self.justActivatedTimer = 0
    --status.overConsumeResource("energy", 0)
  end

  if self.justActivatedTimer > 0 then
    if mcontroller.groundMovement() then mcontroller.controlApproachVelocity({0,0}, 4000) end
    self.justActivatedTimer = self.justActivatedTimer - args.dt
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function findGroundDirection()
  for i = 0, 3 do
    local angle = (i * math.pi / 2) - math.pi / 2
    local collisionSet = i == 1 and self.platformCollisionSet or self.normalCollisionSet
    local testPos = vec2.add(mcontroller.position(), vec2.withAngle(angle, 0.25))
    if world.polyCollision(poly.translate(mcontroller.collisionPoly(), testPos), nil, collisionSet) then
      return vec2.withAngle(angle, 1.0)
    end
  end
end

function plantBeacon()
  if self.beaconCooldownTimer > 0 or not self.shiftHeld then
    return
  end
  local direction = findGroundDirection()
  if direction then
    world.spawnProjectile("ivrpgoperativebeacon", mcontroller.position(), entity.id(), direction, false, {boltPower = status.statusProperty("ivrpgintelligence", 0) + 1})
    self.beaconCooldownTimer = self.beaconCooldown
  end
end

function shootPulse()
  --Tank Sphere missile effect.
  if self.active and self.bombTimer == 0 and status.overConsumeResource("energy", 30) then
    self.bombTimer = 1.5
    local diff = world.distance(tech.aimPosition(), mcontroller.position())
    local aimingAngle = vec2.angle(diff)
    local aimingVector = vec2.rotate({1, 0}, aimingAngle)
    local missileConfig = {power = 10 * status.stat("powerMultiplier")}
    local projectileName = "ivrpgoperativepulse"
    world.spawnProjectile(projectileName, mcontroller.position(), entity.id(), aimingVector, false, missileConfig)
  end
end

function uninit()
  storePosition()
  deactivate()
end

function magnetizeTo(reverse)
  local direction = self.magnetizeDirection
  local collision = world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), direction), {"Block", "Dynamic"})
  local magnetizeSpeed = 100 * (self.beaconActive and 5 or 1)
  if reverse or not collision then
    direction = vec2.mul(direction, -1)
    magnetizeSpeed = 1000
    collision = world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), direction), {"Block", "Dynamic"})
    if not collision then
      self.magnetizeDirection = nil
    end
  end

  if math.abs(direction[1]) > math.abs(direction[2]) then
    turnOffParticles(direction[1] < 0 and 3 or 4)
  else
    turnOffParticles(direction[2] < 0 and 1 or 2)
  end
  mcontroller.controlApproachVelocity(direction, magnetizeSpeed * self.magnetizeTimer)
  if world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), vec2.mul(direction, 1/self.distance)), {"Block", "Dynamic"}) then
    self.magnetizeDirection = nil
  end
end

function turnOffParticles(num)
  local particles = {"Down", "Up", "Left", "Right"}
  for i=1,4 do
    animator.setParticleEmitterOffsetRegion("magnetic" .. particles[i], mcontroller.boundBox())
    if i == num then
      animator.setParticleEmitterActive("magnetic" .. particles[i], true)
    else
      animator.setParticleEmitterActive("magnetic" .. particles[i], false)
    end
  end
end

function findMagnetizePos(normal)
  if not normal then
    return
  end

  local direction = vec2.mul(normal, -self.distance)
  local collision = world.lineTileCollision(mcontroller.position(), vec2.add(mcontroller.position(), direction), {"Block", "Dynamic"})
  if collision then
    self.magnetizeDirection = direction
  end
end

function updateAngularVelocity(dt)
  if mcontroller.groundMovement() then
    -- If we are on the ground, assume we are rolling without slipping to
    -- determine the angular velocity
    local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
    self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

    if positionDiff[1] > 0 then
      self.angularVelocity = -self.angularVelocity
    end
  elseif self.magnetizeDirection then
    self.angularVelocity = 0.1 / dt / self.ballRadius
    if self.magnetizeDirection[1] > 0 or self.magnetizeDirection[2] > 0 then
      self.angularVelocity = - self.angularVelocity
    end
  end
end