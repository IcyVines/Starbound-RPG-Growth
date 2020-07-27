require "/scripts/keybinds.lua"

function init()
  self.active = false
  Bind.create("Up", toggle)
end

function toggle()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("ivrpgquasar")
    animator.playSound("deactivate")
  else
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpgquasar", math.huge)
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgquasar")
end

function update(args)
end
