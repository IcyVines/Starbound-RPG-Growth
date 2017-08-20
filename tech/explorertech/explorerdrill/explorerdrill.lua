require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  self.cost = config.getParameter("cost")
  self.power = config.getParameter("power")
  self.fallTimer = 0
  self.fallTime = config.getParameter("fallTime")
  self.active = false
  self.drill = false
end

function input(args)
  if args.moves["special1"] then
    return "explorerdrill"
  else
    return nil
  end
end

function drill()
  self.id = entity.id()
  self.pos = mcontroller.position()
  world.damageTiles({
  	{self.pos[1], self.pos[2]-2},
  	{self.pos[1], self.pos[2]-3},
  	{self.pos[1]-1, self.pos[2]-2},
  	{self.pos[1]+1, self.pos[2]-2},
    {self.pos[1]-1, self.pos[2]-3},
    {self.pos[1]+1, self.pos[2]-3}
  }, "foreground", mcontroller.position(), "beamish", self.power, 20)
end

function update(args)
  local action = input(args)
  local energyUsagePerSecond = config.getParameter("cost")

  if mcontroller.falling() or mcontroller.jumping() then
  	self.fallTimer = self.fallTimer + args.dt
  	if self.fallTimer >= self.fallTime then
  		self.drill = false
  	end
  elseif mcontroller.onGround() or mcontroller.groundMovement() then
  	self.fallTimer = 0
  	self.drill = true
  end

  if action == "explorerdrill" and status.overConsumeResource("energy", energyUsagePerSecond * args.dt) and not status.statPositive("activeMovementAbilities") and self.drill then
    animator.setAnimationState("drill", "on")

    if not self.active then
      animator.playSound("activate")
    end
    self.active = true
  else
    self.active = false
    animator.setAnimationState("drill", "off")
  end

  if self.active then
  	drill()
  end
  
end

function uninit()
  
end