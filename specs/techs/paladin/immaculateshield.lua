require "/scripts/keybinds.lua"

function init()
  self.active = false
  Bind.create("g", toggle)
end

function toggle()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
    animator.playSound("deactivate")
  else
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpgimmaculateshieldstatus", math.huge)
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
end

function update(args)
end
