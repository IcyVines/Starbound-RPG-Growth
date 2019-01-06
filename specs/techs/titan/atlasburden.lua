require "/scripts/keybinds.lua"

function init()
  self.active = false
  Bind.create("Up", toggle)
end

function toggle()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("ivrpgatlasburden")
  else
    self.active = true
    --animator.playSound("on")
    status.addEphemeralEffect("ivrpgatlasburden", math.huge)
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgatlasburden")
end

function update(args)
end
