require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/keybinds.lua"

function init()
  initCommonParameters()

  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.damageDisableTime = config.getParameter("damageDisableTime")
  self.damageDisableTimer = 0
  
  self.headingAngle = nil
  self.sticking = false

  self.normalCollisionSet = {"Block", "Dynamic"}
  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end

  self.damageListener = damageListener("damageTaken", 
    function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.sourceEntityId ~= entity.id() then
          damaged()
          return
        end
      end
    end
  )

  self.jumpsLeft = config.getParameter("multiJumpCount")
  refreshJumps()
  self.glideActive = false

  self.drillCost = config.getParameter("drillCost")
  self.power = config.getParameter("power")
  self.fallTimer = 0
  self.fallTime = config.getParameter("fallTime")
  self.activeDrill = false
  self.drill = false

  self.jumpSpeed = config.getParameter("jumpSpeed")
  Bind.create("jumping", doMultiJump)
end

function update(args)

  local action = input(args)
  self.glideSphere = status.statPositive("ivrpgucglidesphere")
  local lrInput = 0
  if args.moves["left"] then
    lrInput = -1
  elseif args.moves["right"] then
    lrInput = 1
  end

  restoreStoredPosition()

  updateDrill(args)

  if not self.specialLast and args.moves["special3"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special3"]

  if not args.moves["special3"] then
    self.forceTimer = nil
  end

  self.damageDisableTimer = math.max(0, self.damageDisableTimer - args.dt)

  self.damageListener:update()

  self.energyRegenBlock = status.resource("energyRegenBlock")
  if self.active then

    --Gliding
    if self.glideSphere and action == "explorerglide" and canGlide() and status.overConsumeResource("energy", self.drillCost * args.dt) then
      animator.setAnimationState("hover", "on")
      --local velocity = vec2.sub(tech.aimPosition(),mcontroller.position())
      local hoverControlForce = config.getParameter("hoverControlForce")
      mcontroller.controlApproachYVelocity(-2, hoverControlForce)
    else
      animator.setAnimationState("hover", "off")
    end

    if self.glideSphere and canGlide() then
      if math.abs(mcontroller.xVelocity()) < self.ballSpeed then
        mcontroller.addMomentum({lrInput, 0})
      end
      self.angularVelocity = -lrInput * self.ballSpeed
    end
    --End Gliding

    status.setResourcePercentage("energyRegenBlock", 1.0)

    local groundDirection
    if self.damageDisableTimer == 0 then
      groundDirection = findGroundDirection()
    end

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
        mcontroller.controlApproachVelocity(vec2.withAngle(groundAngle, self.ballSpeed), 800)

        local moveDirection = vec2.rotate({moveX, 0}, self.headingAngle)
        mcontroller.controlApproachVelocityAlongAngle(math.atan(moveDirection[2], moveDirection[1]), self.ballSpeed, 2000)

        self.angularVelocity = -moveX * self.ballSpeed
      else
        mcontroller.controlApproachVelocity({0,0}, 2000)
        self.angularVelocity = 0
      end

      mcontroller.controlDown()

      status.setResourcePercentage("energyRegenBlock", 1.0)
      updateAngularVelocity(args.dt)

      self.transformedMovementParameters.gravityEnabled = false
      self.sticking = true
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
      if self.jumpDirection then
        mcontroller.setVelocity(vec2.mul(vec2.norm(vec2.add(self.jumpDirection,{0,1})),self.jumpSpeed))
        self.jumpDirection = nil
      end
      self.sticking = false
    end

    mcontroller.controlParameters(self.transformedMovementParameters)

    updateRotationFrame(args.dt)

    checkForceDeactivate(args.dt)

    if mcontroller.groundMovement() or mcontroller.liquidMovement() or self.sticking then
      refreshJumps()
    end

  else
    self.sticking = false
    self.headingAngle = nil
    --status.overConsumeResource("energy", 0)
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function updateDrill(args)
  local action = input(args)
  local energyUsagePerSecond = self.drillCost

  --[[ if mcontroller.falling() or mcontroller.jumping() then
    self.fallTimer = self.fallTimer + args.dt
    if self.fallTimer >= self.fallTime then
      self.drill = false
    end
  elseif mcontroller.onGround() or mcontroller.groundMovement() then
    self.fallTimer = 0
    self.drill = true
  end]]--

  if action == "explorerdrill" and status.overConsumeResource("energy", energyUsagePerSecond * args.dt) then--and self.drill then
    if self.active then
      animator.setAnimationState("drillSphere", "on")
    else
      animator.setAnimationState("drill", "on")
    end

    if not self.activeDrill then
      animator.playSound("activate")
    end
    self.activeDrill = true
  else
    self.activeDrill = false
    animator.setAnimationState("drill", "off")
    animator.setAnimationState("drillSphere", "off")
  end

  if self.activeDrill then
    drill()
  end
  
end

function damaged()
  if self.active then
    self.damageDisableTimer = self.damageDisableTime
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

function drill()
  self.id = entity.id()
  self.pos = mcontroller.position()
  world.damageTiles({
    {self.pos[1], self.pos[2]-1},
    {self.pos[1], self.pos[2]-2},
    {self.pos[1], self.pos[2]-3},
    {self.pos[1]-1, self.pos[2]-1},
    {self.pos[1]+1, self.pos[2]-1},
    {self.pos[1]-1, self.pos[2]-2},
    {self.pos[1]+1, self.pos[2]-2},
    {self.pos[1]-1, self.pos[2]-3},
    {self.pos[1]+1, self.pos[2]-3}
  }, "foreground", mcontroller.position(), "beamish", self.power, 20)
end

function input(args)
  if args.moves["up"] then
    return "explorerglide"
  elseif args.moves["special1"] then
    return "explorerdrill"
  else
    return nil
  end
end

function groundJump()
  local groundDirection = findGroundDirection()
  if groundDirection then
    groundDirection = {util.round(groundDirection[1]), util.round(groundDirection[2])}
    sb.logInfo("Ground Direction: " .. groundDirection[1] .. ", " .. groundDirection[2])
    if groundDirection[2] == -1 then
      self.jumpDirection = vec2.norm(mcontroller.velocity())
    else 
      self.jumpDirection = {-groundDirection[1], -groundDirection[2]}
    end
    self.damageDisableTimer = self.damageDisableTime
    sb.logInfo("Jump Direction: " .. self.jumpDirection[1] .. ", " .. self.jumpDirection[2])
  end
end

function doMultiJump()
  if self.sticking then
    groundJump()
  elseif canMultiJump() then
    mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()) + self.ballSpeed*3)
    animator.burstParticleEmitter("jumpParticles")
    self.jumpsLeft = self.jumpsLeft - 1
    animator.playSound("multiJumpSound")
  end
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not self.sticking
      and not mcontroller.liquidMovement()
      and math.abs(world.gravity(mcontroller.position())) > 0
      and self.active and self.glideSphere
end

function canGlide()
  return not self.sticking
      and not mcontroller.liquidMovement()
      and math.abs(world.gravity(mcontroller.position())) > 0
      and self.active and self.glideSphere
end

function refreshJumps()
  if self.glideSphere then
    self.jumpsLeft = config.getParameter("multiJumpCount") + 1
  else
    self.jumpsLeft = config.getParameter("multiJumpCount")
  end
end
