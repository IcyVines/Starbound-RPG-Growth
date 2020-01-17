require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/tech/ninjatech/flashjump/flashjump.lua"
require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.cost = config.getParameter("cost")
  self.maxSpeed = 30
  self.liquidTimer = 0

  self.wallSlideParameters = config.getParameter("wallSlideParameters")
  self.wallJumpXVelocity = config.getParameter("wallJumpXVelocity")
  self.melty = false
  self.meltyBounds = poly.boundBox(config.getParameter("meltyPoly"))
  self.sliding = false
  buildSensors()
  self.wallDetectThreshold = config.getParameter("wallDetectThreshold")
  self.wallCollisionSet = {"Dynamic", "Block"}

  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
  --self.wallBind = Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doWallJump, false)
  self.slideBind = Bind.create("Down=true", beginSlide)
  --self.wallBind:unbind()
  self.slideBind:unbind()

  refreshJumps()
  releaseWall()
  
end

function input(args)
  if args.moves["down"] then
    return "slide"
  else
    return nil
  end
end

function update(args)

  if (status.statPositive("ivrpgmeltyblood") and not self.melty) or (self.melty and not status.statPositive("ivrpgmeltyblood")) then
    self.melty = not self.melty
    buildSensors()
  end

  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  self.lrInput = nil
  if args.moves["left"] and not args.moves["right"] then
    self.lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    self.lrInput = "right"
  end

  local action = input(args)

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    if not mcontroller.liquidMovement() then
      status.removeEphemeralEffect("nofalldamage")
      status.removeEphemeralEffect("ivrpgjumpcamouflage")
      self.liquidTimer = 0
    else
      self.liquidTimer = self.liquidTimer + args.dt
      if self.liquidTimer > 0.2 then
        self.liquidTimer = 0
        status.removeEphemeralEffect("nofalldamage")
        status.removeEphemeralEffect("ivrpgjumpcamouflage")
      end
    end
    refreshJumps()
    if self.wall then
      releaseWall()
    end
  elseif self.wall then
    mcontroller.controlParameters(self.wallSlideParameters)
    self.wallSlideParameters.airFriction = 10
    refreshJumps()
    --self.wallBind:rebind()

    if not checkWall(self.wall) or status.statPositive("activeMovementAbilities") or ((self.lrInput == "right" or self.lrInput == "left") and self.lrInput ~= self.wall) then
      releaseWall()
    elseif jumpActivated then
      mcontroller.controlParameters(self.wallSlideParameters)
      doWallJump()
    elseif not self.sliding then
      self.slideBind:rebind()
      self.wallSlideParameters.airFriction = 100
      mcontroller.controlFace(self.wall == "left" and 1 or -1)
    elseif self.sliding then
      mcontroller.controlFace(self.wall == "left" and 1 or -1)
      if self.lrInput and not mcontroller.jumping() and checkWall(self.lrInput) then
        grabWall(self.lrInput)
      end    
    end
  elseif not status.statPositive("activeMovementAbilities") then
    if self.lrInput and not mcontroller.jumping() and checkWall(self.lrInput) then
      grabWall(self.lrInput)
    end
  end

  if status.resource("energy") < 1 or status.statPositive("activeMovementAbilities") then
    status.removeEphemeralEffect("ivrpgjumpcamouflage")
    status.removeEphemeralEffect("nofalldamage")
  end

end

function canMultiJump()
  return self.multiJumpCount > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and not self.wall
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function beginSlide()
  if self.wall then
    self.sliding = true
    self.slideBind:unbind()
    animator.setParticleEmitterActive("wallSlide."..self.wall, true)
    animator.playSound("wallSlideLoop", -1)
  end
end

function buildSensors()
  local bounds = status.statPositive("ivrpgmeltyblood") and self.meltyBounds or poly.boundBox(mcontroller.baseParameters().standingPoly) 
  self.wallSensors = {
    right = {},
    left = {}
  }
  for _, offset in pairs(config.getParameter("wallSensors")) do
    table.insert(self.wallSensors.left, {bounds[1] - 0.1, bounds[2] + offset / (status.statPositive("ivrpgmeltyblood") and 2 or 1)})
    table.insert(self.wallSensors.right, {bounds[3] + 0.1, bounds[2] + offset / (status.statPositive("ivrpgmeltyblood") and 2 or 1)})
  end
end

function checkWall(wall)
  local pos = mcontroller.position()
  local wallCheck = 0
  for _, offset in pairs(self.wallSensors[wall]) do
    -- world.debugPoint(vec2.add(pos, offset), world.pointCollision(vec2.add(pos, offset), self.wallCollisionSet) and "yellow" or "blue")
    if world.pointCollision(vec2.add(pos, offset), self.wallCollisionSet) then
      wallCheck = wallCheck + 1
    end
  end
  return wallCheck >= self.wallDetectThreshold / (status.statPositive("ivrpgmeltyblood") and 2 or 1)
end

function doWallJump()
  mcontroller.controlJump(true)
  animator.playSound("wallJumpSound")
  animator.burstParticleEmitter("wallJump."..self.wall)
  mcontroller.setXVelocity(self.wall == "left" and self.wallJumpXVelocity or -self.wallJumpXVelocity)
  releaseWall()
end

function grabWall(wall)
  self.wall = wall
  releaseSlide()
  mcontroller.setVelocity({0, 0})
  tech.setToolUsageSuppressed(true)
  tech.setParentState("fly")
  animator.playSound("wallGrab")
end

function releaseSlide()
  self.sliding = false
  animator.setParticleEmitterActive("wallSlide.left", false)
  animator.setParticleEmitterActive("wallSlide.right", false)
  animator.stopAllSounds("wallSlideLoop")
end

function releaseWall()
  self.slideBind:unbind()
  --self.wallBind:unbind()
  self.wall = nil
  tech.setToolUsageSuppressed(false)
  tech.setParentState()
  releaseSlide()
end

function uninit()
  releaseWall()
end