require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/tech/jump/walljump.lua"
require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.active = false
  self.multiJumpModifier = config.getParameter("multiJumpModifier")

  self.wallSlideParameters = config.getParameter("wallSlideParameters")
  self.wallJumpXVelocity = config.getParameter("wallJumpXVelocity")
  self.wallGrabFreezeTime = config.getParameter("wallGrabFreezeTime")
  self.wallGrabFreezeTimer = 0
  self.wallReleaseTime = config.getParameter("wallReleaseTime")
  self.wallReleaseTimer = 0

  buildSensors()
  self.wallDetectThreshold = config.getParameter("wallDetectThreshold")
  self.wallCollisionSet = {"Dynamic", "Block"}


  refreshJumps()
  releaseWall()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
end

function input(args)
  if args.moves["up"] and canGlide() then
    return "explorerglide"
  else
    return nil
  end
end

function uninit()
  releaseWall()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
  updateJumpModifier()

  local action = input(args)
  local agility = world.entityCurrency(entity.id(), "agilitypoint")
  local energyUsagePerSecond = config.getParameter("energyUsagePerSecond") - ( agility^2 / 200.0 )
  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    lrInput = "right"
  end

  if action == "explorerglide" and status.overConsumeResource("energy", energyUsagePerSecond * args.dt) and not status.statPositive("activeMovementAbilities") then
    animator.setAnimationState("hover", "on")

    --local velocity = vec2.sub(tech.aimPosition(),mcontroller.position())
    local hoverControlForce = config.getParameter("hoverControlForce")

    mcontroller.controlApproachYVelocity(-2, hoverControlForce)

    if not self.active then
      animator.playSound("activate")
    end
    self.active = true
  else
    self.active = false
    animator.setAnimationState("hover", "off")
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
    if self.wall then
      releaseWall()
    end
  elseif self.wall then
    self.applyJumpModifier = false
    mcontroller.controlParameters(self.wallSlideParameters)

    if not checkWall(self.wall) or status.statPositive("activeMovementAbilities") then
      releaseWall()
    elseif jumpActivated then
      doWallJump() 
    else
      if lrInput and lrInput ~= self.wall then
        self.wallReleaseTimer = self.wallReleaseTimer + args.dt
      else
        self.wallReleaseTimer = 0
      end

      if self.wallReleaseTimer > self.wallReleaseTime then
        releaseWall()
      else
        mcontroller.controlFace(self.wall == "left" and 1 or -1)
        if self.wallGrabFreezeTimer > 0 then
          self.wallGrabFreezeTimer = math.max(0, self.wallGrabFreezeTimer - args.dt)
          mcontroller.controlApproachVelocity({0, 0}, 1000)
          if self.wallGrabFreezeTimer == 0 then
            animator.setParticleEmitterActive("wallSlide."..self.wall, true)
            animator.playSound("wallSlideLoop", -1)
          end
        end
      end
    end
  elseif not status.statPositive("activeMovementAbilities") then
    if lrInput and not mcontroller.jumping() and checkWall(lrInput) then
      grabWall(lrInput)
    end
  end
end

function updateJumpModifier()
  if self.multiJumpModifier then
    if not self.applyJumpModifier
        and not mcontroller.jumping()
        and not mcontroller.groundMovement() then

      self.applyJumpModifier = true
    end

    if self.applyJumpModifier then mcontroller.controlModifiers({airJumpModifier = self.multiJumpModifier}) end
  end
end

function doMultiJump()
  if self.wall then
    return
    --doWallJump()
  elseif not canMultiJump() then
    return
  else
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
    animator.burstParticleEmitter("jumpParticles")
    self.jumpsLeft = self.jumpsLeft - 1
    animator.playSound("multiJumpSound")
  end
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      --and not self.wall
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function canGlide()
  return not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function refreshJumps()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.applyJumpModifier = false
end

