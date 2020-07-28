require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.active = false
  Bind.create("Up", toggle)
end

function toggle()
  if not self.active and not status.resourceLocked("energy") then
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpgquasarcamouflage", math.huge)
  elseif self.active then
    weaken()
    animator.playSound("deactivate")
    reset()
  end
end

function weaken()

end

function reset()
  self.active = false
  status.removeEphemeralEffect("ivrpgquasarcamouflage")
end

function uninit()
  reset()
end

function update(args)
  if not hasEphemeralStat(status.activeUniqueStatusEffectSummary(), "ivrpgquasarcamouflage") then
    self.active = false
  end
end
