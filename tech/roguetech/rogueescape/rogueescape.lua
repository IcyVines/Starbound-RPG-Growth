require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.rechargeEffectTimer = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=21A81AFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.vDirectionLocked = 0
  self.hDirectionLocked = 0

  self.wallSlideParameters = config.getParameter("wallSlideParameters")
  self.wallJumpXVelocity = config.getParameter("wallJumpXVelocity")
  self.wallGrabFreezeTime = config.getParameter("wallGrabFreezeTime")
  self.wallGrabFreezeTimer = 0
  self.wallReleaseTime = config.getParameter("wallReleaseTime")
  self.wallReleaseTimer = 0
  self.wavedashTimer = 0
  self.pulseTime = 0

  buildSensors()
  self.wallDetectThreshold = config.getParameter("wallDetectThreshold")
  self.wallCollisionSet = {"Dynamic", "Block"}

  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)

  releaseWall()

end

function uninit()
  status.clearPersistentEffects("movementAbility")
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  releaseWall()
  tech.setParentDirectives()
end

function update(args)

  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  self.wavedash = status.statPositive("ivrpgucwavedash")
  self.walljump = status.statPositive("ivrpgucwalljump")

  --Find Directional Input
  self.hDirection = 0
  self.vDirection = 0
  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    self.hDirection = -1
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    self.hDirection = 1
    lrInput = "right"
  end
  if args.moves["up"] and not args.moves["down"] then
    self.vDirection = 1
  elseif args.moves["down"] and not args.moves["up"] then
    self.vDirection = -1
  end

  if self.dashTimer > 0 then
    local groundSpeedBonus = 1
    local controlForceBonus = 1
    if self.wavedash then
      status.addEphemeralEffect("nofalldamage", 2)
      if mcontroller.groundMovement() then
        self.wavedashTimer = 0.15
      end
    end
    self.agility = status.statusProperty("ivrpgagility", 0)
    self.agilityModifier = 1 + (self.agility^0.9 / 100)
    if self.vDirectionLocked == 0 or self.hDirectionLocked == 0 then
      mcontroller.controlApproachVelocity({self.dashSpeed * self.hDirectionLocked * self.agilityModifier, self.dashSpeed * self.vDirectionLocked * self.agilityModifier}, self.dashControlForce)
    else
      mcontroller.controlApproachVelocity({self.dashSpeed/1.41 * self.hDirectionLocked * self.agilityModifier, self.dashSpeed/1.41 * self.vDirectionLocked * self.agilityModifier}, self.dashControlForce)
    end
    if self.wavedashTimer > 0 then
      mcontroller.setXVelocity(self.dashSpeed*self.hDirectionLocked*(1+(self.agility^0.9)/200)*1.5)
      --mcontroller.controlApproachXVelocity(self.dashSpeed*self.hDirectionLocked*(1+self.agility/100)*groundSpeedBonus, self.dashControlForce*controlForceBonus)
    end
    mcontroller.controlMove(self.hDirectionLocked, true)
    mcontroller.controlModifiers({jumpingSuppressed = true})
    animator.setFlipped(mcontroller.facingDirection() == -1)
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer == 0 or mcontroller.groundMovement() or mcontroller.liquidMovement() then
      endDash()
    end
  end

  if self.wavedashTimer > 0 then
    self.wavedashTimer = math.max(0, self.wavedashTimer - args.dt)
    self.pulseTime = math.max(0, self.pulseTime - args.dt)
    if mcontroller.groundMovement() and mcontroller.xVelocity() ~= 0 and self.pulseTime == 0 then
      self.pulseTime = 0.05
      world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition(), mcontroller.yPosition()-2}, entity.id(), {0,0}, false, {})
    end
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
    status.removeEphemeralEffect("nofalldamage")
    if self.wall then
      releaseWall()
    end
  elseif self.wall then
    refreshJumps()
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
  elseif self.walljump then
    if lrInput and not mcontroller.jumping() and checkWall(lrInput) then
      grabWall(lrInput)
    end
  end

end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  --mcontroller.controlJump(true)
  startDash()
  --animator.burstParticleEmitter("jumpParticles")
  self.jumpsLeft = self.jumpsLeft - 1
  --animator.playSound("multiJumpSound")
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and not self.wall
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function refreshJumps()
  self.jumpsLeft = config.getParameter("multiJumpCount")
end

function startDash()
  self.vDirectionLocked = self.vDirection
  self.hDirectionLocked = (self.vDirectionLocked == 0 and self.hDirection == 0) and mcontroller.facingDirection()*-1 or self.hDirection
  if self.wavedash then
    if self.vDirectionLocked == 0 and self.hDirection == 0 then self.vDirectionLocked = -1 end
  end
  self.dashTimer = self.dashDuration
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  mcontroller.setVelocity({0, 0})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
  spawnSmoke()
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  local movementParams = mcontroller.baseParameters()
  local currentVelocity = mcontroller.velocity()
  if self.wavedash and not mcontroller.onGround() then mcontroller.setVelocity(vec2.mul(currentVelocity, 0.6)) end
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function spawnSmoke()
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()+1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()-1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()+1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()-1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
end

function buildSensors()
  local bounds = poly.boundBox(mcontroller.baseParameters().standingPoly)
  self.wallSensors = {
    right = {},
    left = {}
  }
  for _, offset in pairs(config.getParameter("wallSensors")) do
    table.insert(self.wallSensors.left, {bounds[1] - 0.1, bounds[2] + offset})
    table.insert(self.wallSensors.right, {bounds[3] + 0.1, bounds[2] + offset})
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
  return wallCheck >= self.wallDetectThreshold
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
  self.wallGrabFreezeTimer = self.wallGrabFreezeTime
  self.wallReleaseTimer = 0
  mcontroller.setVelocity({0, 0})
  tech.setToolUsageSuppressed(true)
  tech.setParentState("fly")
  animator.playSound("wallGrab")
end

function releaseWall()
  self.wall = nil
  tech.setToolUsageSuppressed(false)
  tech.setParentState()
  animator.setParticleEmitterActive("wallSlide.left", false)
  animator.setParticleEmitterActive("wallSlide.right", false)
  animator.stopAllSounds("wallSlideLoop")
end