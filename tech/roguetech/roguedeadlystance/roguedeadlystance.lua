require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  --[[self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=25492EFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.auraRechargeDirectives = config.getParameter("rechargeDirectives", "?fade=89A04EFF=0.25")
  self.auraRechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)]]
  self.energyCost = config.getParameter("energyCost")
  self.auraActive = false
  Bind.create("g", deadlyStance)
end

function uninit()
  status.removeEphemeralEffect("rdeadlystance")
  deactivateAura()
  tech.setParentDirectives()
end

function deadlyStance()
  if not (self.auraActive or status.resourceLocked("energy")) then
    activateAura()
  else
    deactivateAura()
  end
end

function update(args)
  if self.auraActive and not status.overConsumeResource("energy", args.dt * self.energyCost) then
    deactivateAura()
  end
end

function activateAura()
    self.auraActive = true
    status.addEphemeralEffect("rdeadlystance", math.huge)
end

function deactivateAura()
    self.auraActive = false
    status.removeEphemeralEffect("rdeadlystance")
end