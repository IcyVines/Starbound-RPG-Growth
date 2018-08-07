require "/scripts/keybinds.lua"

function init()
  self.timer = 0
  Bind.create("g", toggle)
end

function toggle()
  if self.timer == 0 then
  	status.addEphemeralEffect("ivrpgdesperadostatus", 5)
  	self.timer = 35
  end
end

function uninit()
  tech.setParentDirectives()
end

function update(args)
	self.timer = math.max(0, self.timer - args.dt)
end
