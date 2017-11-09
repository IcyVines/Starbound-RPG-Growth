require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()
  initCommonParameters()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.headingAngle = nil
  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.normalCollisionSet = {"Block", "Dynamic"}

  self.pressBlock = false
  self.pressFire = false
  self.bombTimer = 0
  self.immunityshieldOn = nil

  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end

end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]
  self.pressBlock = args.moves["altFire"]
  self.pressFire = args.moves["primaryFire"]
  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  if self.active then

      if self.bombTimer > 0 then
        self.bombTimer = math.max(0, self.bombTimer - args.dt)
      end

    --Tank Sphere missile effect.
    if self.pressFire and self.bombTimer == 0 then
      self.bombTimer = 1.5
      self.cursor = tech.aimPosition()

      local diff = world.distance(self.cursor, mcontroller.position())
      local aimingAngle = vec2.angle(diff)
      local aimingVector = vec2.rotate({1, 0}, aimingAngle)

--      soldiertankmissiledamageConfig = {
--        power = self.damage
--      }
      world.spawnProjectile("soldiertankmissile", mcontroller.position(), entity.id(), aimingVector, false)
    end

    --Tank Sphere immunity effect
    if self.pressBlock and status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
      activateImmunityShields()
    else
      deactivateImmunityShields()
    end

    local groundDirection = findGroundDirection()

    if groundDirection then
      if not self.headingAngle then
        self.headingAngle = (math.atan(groundDirection[2], groundDirection[1]) + math.pi / 2) % (math.pi * 2)
      end

      local moveX = 0
      if args.moves["right"] then moveX = moveX + 1 end
      if args.moves["left"] then moveX = moveX - 1 end
      if moveX ~= 0 then
        -- find any collisions in the moving direction, and adjust heading angle *up* until there is no collision
        -- this makes the heading direction follow concave corners
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
        mcontroller.controlApproachVelocity(vec2.withAngle(groundAngle, self.ballSpeed), 300)

        local moveDirection = vec2.rotate({moveX, 0}, self.headingAngle)
        mcontroller.controlApproachVelocityAlongAngle(math.atan(moveDirection[2], moveDirection[1]), self.ballSpeed, 2000)

        self.angularVelocity = -moveX * self.ballSpeed
      else
        mcontroller.controlApproachVelocity({0,0}, 2000)
        self.angularVelocity = 0
      end

      mcontroller.controlDown()
      updateAngularVelocity(args.dt)

      self.transformedMovementParameters.gravityEnabled = false
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
    end

    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    updateRotationFrame(args.dt)

    checkForceDeactivate(args.dt)
  else
    self.headingAngle = nil
     -- DisableEffects --
    deactivateImmunityShields()
  end
 
  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function activateImmunityShields()
    if not self.immunityshieldOn then
      status.addEphemeralEffect("soldiertanksphereimmune", math.huge)
      self.immunityshieldOn = world.spawnProjectile("soldiertanksphereshield",
                                            mcontroller.position(),
                                            entity.id(),
                                            {0,0},
                                            true,
                                            {}
                                           )
    end
end

function deactivateImmunityShields()
    if self.immunityshieldOn then
      status.removeEphemeralEffect("soldiertanksphereimmune")
      world.entityQuery(mcontroller.position(),1,
        {
         withoutEntityId = entity.id(),
         includedTypes = {"projectile"},
         callScript = "immunityshieldRemoval",
         callScriptArgs = {self.immunityshieldOn}
        }
      )
      self.immunityshieldOn = nil
    end
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
