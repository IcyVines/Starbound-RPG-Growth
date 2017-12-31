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

    local agility = world.entityCurrency(entity.id(),"agilitypoint") or 1
    local maxSpeed = agility^2 / 180.0 + 25
    local velocity = world.distance(tech.aimPosition(),mcontroller.position())
    --local direction = mcontroller.facingDirection()
    velocity = vec2.mag(velocity) > maxSpeed and vec2.withAngle(vec2.angle(velocity), maxSpeed) or velocity
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
