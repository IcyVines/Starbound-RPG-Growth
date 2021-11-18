require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.active = false
  Bind.create("f", activate)
end

function activate()
  if not self.active then
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpgberserkstatus", math.huge)
  else
    self.active = false
    animator.playSound("deactivate")
    status.removeEphemeralEffect("ivrpgberserkstatus")
  end
end

function reset()
  animator.playSound("deactivate")
  self.active = false
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgberserkstatus")
end

function update(args)
  if self.active and not status.uniqueStatusEffectActive("ivrpgberserkstatus") then
    reset()
  end
end