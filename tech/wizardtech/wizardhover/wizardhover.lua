require "/scripts/vec2.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.holdingJump = false
  self.active = false
  self.hoverControlForce = config.getParameter("hoverControlForce")
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
  local hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  local vDirection = args.moves["down"] and -1 or (args.moves["up"] and 1 or 0)
  local energyOff = (vDirection == -1 and hDirection == 0) and 4 or (vDirection == -1 and 3 or ((hDirection == 0 and vDirection == 0) and 2 or (vDirection == 1 and 0.5 or 1)))

  if action == "wizardhover" and status.overConsumeResource("energy", energyUsagePerSecond * args.dt / energyOff) and not status.statPositive("activeMovementAbilities") then
    animator.setAnimationState("hover", "on")

    local agility = status.statusProperty("ivrpgagility", 0)
    local intelligence = status.statusProperty("ivrpgintelligence", 0)
    local maxSpeed = math.min(agility^0.9 + intelligence^0.7 + 10, 50)
    local angle = (hDirection ~= 0 or vDirection ~= 0) and vec2.angle({hDirection, vDirection}) or false
    local velocity = angle and vec2.withAngle(angle, maxSpeed) or {0,0}
    mcontroller.controlApproachVelocity(velocity, self.hoverControlForce)
    if vDirection == 0 then mcontroller.controlApproachYVelocity(0, self.hoverControlForce) end

    if not self.active then
      animator.playSound("activate")
    end
    self.active = true
  else
    if self.active then
      mcontroller.controlApproachVelocity({0,0}, self.hoverControlForce * 10)
    end
    self.active = false
    animator.setAnimationState("hover", "off")
  end
end
