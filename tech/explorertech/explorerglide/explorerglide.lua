require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.active = false
  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
end

function input(args)
  if args.moves["up"] and canGlide() then
    return "explorerglide"
  else
    return nil
  end
end

function update(args)
  local action = input(args)
  local agility = world.entityCurrency(entity.id(), "agilitypoint")
  local energyUsagePerSecond = config.getParameter("energyUsagePerSecond") - ( agility^2 / 200.0 )

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
  end
end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
  animator.burstParticleEmitter("jumpParticles")
  self.jumpsLeft = self.jumpsLeft - 1
  animator.playSound("multiJumpSound")
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
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
end