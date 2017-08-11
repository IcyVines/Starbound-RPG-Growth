require "/scripts/vec2.lua"

function init()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.multiJumpModifier = config.getParameter("multiJumpModifier")
  refreshJumps()

  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.cooldown = config.getParameter("cooldown", 2)
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=3CB34CFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  updateJumpModifier()

  if jumpActivated and canMultiJump() and self.cooldownTimer == 0 then
    doMultiJump()
    self.cooldownTimer = self.cooldown
  else
    if mcontroller.groundMovement() or mcontroller.liquidMovement() then
      refreshJumps()
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end
end

-- after the original ground jump has finished, start applying the new jump modifier
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

function canMultiJump()
  return self.multiJumps > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function doMultiJump()
  mcontroller.setYVelocity(0)
  world.spawnVehicle("cloudplatform", vec2.sub(mcontroller.position(),{0,3}))
  self.multiJumps = self.multiJumps - 1
  animator.playSound("multiJumpSound")
end

function refreshJumps()
  self.multiJumps = self.multiJumpCount
  self.applyJumpModifier = false
end
