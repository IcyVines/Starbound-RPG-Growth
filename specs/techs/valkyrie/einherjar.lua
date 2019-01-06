require "/scripts/keybinds.lua"

function init()
  self.active = false
  Bind.create("Up", toggle)
end

function toggle()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
  else
    self.active = true
    --animator.playSound("on")
    status.addEphemeralEffect("ivrpgimmaculateshieldstatus", math.huge)
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
end

function update(args)
end
