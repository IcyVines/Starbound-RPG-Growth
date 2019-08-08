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

  if action == "wizardhover" and status.overConsumeResource("energy", energyUsagePerSecond * args.dt) and not status.statPositive("activeMovementAbilities") then
    animator.setAnimationState("hover", "on")

    local agility = status.statusProperty("ivrpgagility", 0)
    local maxSpeed = math.min(agility^0.6 + 25, 45)
    local mouseDistance = world.distance(tech.aimPosition(),mcontroller.position())
    local speedFactor = math.min(vec2.mag(mouseDistance), 10) / 10
    local velocity = vec2.withAngle(vec2.angle(mouseDistance), maxSpeed * speedFactor)
    velocity = {velocity[1],velocity[2] / 1.5}
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
