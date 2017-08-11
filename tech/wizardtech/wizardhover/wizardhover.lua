require "/scripts/vec2.lua"

function init()
  self.holdingJump = false
  self.active = false
end

function input(args)
  if args.moves["jump"] and mcontroller.jumping() then
    self.holdingJump = true
  elseif not args.moves["jump"] then
    self.holdingJump = false
  end

  if args.moves["jump"] and not mcontroller.canJump() and not self.holdingJump then
    return "wizardhover"
  else
    return nil
  end
end

function update(args)
  local action = input(args)
  local energyUsagePerSecond = config.getParameter("energyUsagePerSecond")

  if action == "wizardhover" and status.consumeResource("energy", energyUsagePerSecond * args.dt) then
    animator.setAnimationState("hover", "on")

    local velocity = vec2.sub(tech.aimPosition(),mcontroller.position())
    local hoverControlForce = config.getParameter("hoverControlForce")

    mcontroller.controlApproachVelocity(velocity, hoverControlForce)

    if not self.active then
      animator.playSound("activate")
    end
    self.active = true
  else
    self.active = false
    animator.setAnimationState("hover", "off")
  end
end
