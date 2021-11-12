require "/scripts/keybinds.lua"

function init()
  self.active = false
  Bind.create("g", toggle)
end

function toggle()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("ivrpgatlasburden")
    animator.playSound("deactivate")
  else
    self.active = true
    --animator.playSound("on")
    status.addEphemeralEffect("ivrpgatlasburden", math.huge)
    animator.playSound("activate")
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgatlasburden")
end

function update(args)
end
