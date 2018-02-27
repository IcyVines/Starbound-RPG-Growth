require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"

function init()
  initCommonParameters()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.damageDisableTime = config.getParameter("damageDisableTime")
  self.damageDisableTimer = 0
  self.headingAngle = nil

  self.normalCollisionSet = {"Block", "Dynamic"}
  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end
  
  self.noCollisionPoly = mcontroller.collisionPoly()
  for i,set in ipairs(self.noCollisionPoly) do
    self.noCollisionPoly[i] = vec2.mul(set,1.2)
  end
  self.ghostOn = nil
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]

  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  self.damageDisableTimer = math.max(0, self.damageDisableTimer - args.dt)

  self.energyRegenBlock = status.resource("energyRegenBlock")
  self.ghost = status.statPositive("ivrpgucghost")
  self.noCollision = self.active and args.moves["primaryFire"] and self.ghost and status.overConsumeResource("energy", self.energyCostPerSecond * args.dt / 2)

  if self.noCollision then
    activateGhost()
      mcontroller.controlParameters(
        {
          collisionEnabled = false
        }
      )
  else
    deactivateGhost()
  end

  if self.active then

    status.setResourcePercentage("energyRegenBlock", 1.0)
    local groundDirection
    if self.damageDisableTimer == 0 then
      groundDirection = findGroundDirection()
    end
    --invulnerable while active
    if (not self.ghost) and status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
      animator.setAnimationState("ballState", "on")
      status.addEphemeralEffect("camouflageninja", math.huge)
      status.setPersistentEffects("vanishsphere",
      {
        {stat = "invulnerable", amount = 1},
        {stat = "ninjaVanishSphere", amount = 1}
      })
    end

    if groundDirection then
      if not self.headingAngle then
        self.headingAngle = (math.atan(groundDirection[2], groundDirection[1]) + math.pi / 2) % (math.pi * 2)
      end

      local moveX = 0
      if args.moves["right"] then moveX = moveX + 1 end
      if args.moves["left"] then moveX = moveX - 1 end
      
      local moveY = 0
      if args.moves["up"] then moveY = moveY + 1 end
      if args.moves["down"] then moveY = moveY - 1 end

      if self.noCollision then

        local adjustedSpeed = self.ballSpeed
        if (moveY ~= 0) and (moveX ~= 0) then
          adjustedSpeed = self.ballSpeed/math.sqrt(2)
        end
        if world.polyCollision(self.noCollisionPoly, mcontroller.position(), {"Block"}) then
          mcontroller.controlApproachVelocity({moveX*adjustedSpeed,moveY*adjustedSpeed}, 2000)
        end
        self.angularVelocity = -moveX * self.ballSpeed

      elseif moveX ~= 0 then
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
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
    end

    mcontroller.controlParameters(self.transformedMovementParameters)

    updateRotationFrame(args.dt)

    checkForceDeactivate(args.dt)

    if status.resource("energy") == 0 or self.ghost then
      --uninit()
      animator.setAnimationState("ballState", "onv")
      status.removeEphemeralEffect("camouflageninja")
      status.setPersistentEffects("vanishsphere",
      {
        {stat = "invulnerable", amount = 0},
        {stat = "ninjaVanishSphere", amount = 1}
      })
    end

  else
    status.removeEphemeralEffect("camouflageninja")
    status.clearPersistentEffects("vanishsphere")
    animator.setAnimationState("ballState", "off")
    self.headingAngle = nil
    --status.overConsumeResource("energy", 0)
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

function uninit()
  storePosition()
  deactivate()
  deactivateGhost()
  status.removeEphemeralEffect("camouflageninja")
  status.clearPersistentEffects("vanishsphere")
end

function activateGhost()
    if not self.ghostOn then
      status.addEphemeralEffect("ninjavanishsphereghost", math.huge)
      self.ghostOn = world.spawnProjectile("ninjavanishspheresurround",
                                            mcontroller.position(),
                                            entity.id(),
                                            {0,0},
                                            true,
                                            {}
                                           )
    end
end

function deactivateGhost()
    if self.ghostOn then
      status.removeEphemeralEffect("ninjavanishsphereghost")
      world.entityQuery(mcontroller.position(),1,
        {
         withoutEntityId = entity.id(),
         includedTypes = {"projectile"},
         callScript = "removeGhost",
         callScriptArgs = {self.ghostOn}
        }
      )
      self.ghostOn = nil
    end
end

function attemptActivation()
  if not self.active
      and not tech.parentLounging()
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.energyCost) then

    local pos = transformPosition()
    if pos then
      mcontroller.setPosition(pos)
      activate()
    elseif self.ghost then
      activate()
    end
  elseif self.active then
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