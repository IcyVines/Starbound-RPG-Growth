require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.active = false
  Bind.create("Up", activate)
end

function activate()
  if not self.active and not status.uniqueStatusEffectActive("ivrpglimitbreakcooldown") then
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpglimitbreakstatus", 10)
  end
end

function reset()
  animator.playSound("deactivate")
  self.active = false
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpglimitbreakstatus")
  status.removeEphemeralEffect("ivrpglimitbreakcooldown")
end

function update(args)
  if self.active and not status.uniqueStatusEffectActive("ivrpglimitbreakstatus") then
    reset()
  end
end