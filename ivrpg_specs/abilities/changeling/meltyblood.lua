require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.healthPercent = config.getParameter("healthPercent", 0.15)
  self.transformedMovementParameters = config.getParameter("movementParameters")
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.unmelt = false
end


function update(dt)

  local melt = status.statusProperty("ivrpgshapeshift", false) and status.resource("health") / status.stat("maxHealth") <= self.healthPercent
  if status.statusProperty("ivrpgshapeshiftC", "") == "giant" then melt = false end
  if self.unmelt and not melt then
    mcontroller.translate({0,1})
  end
  self.unmelt = melt
  status.setPersistentEffects("ivrpgmeltyblood", {
    { stat = "physicalResistance", amount = melt and 0.5 or 0},
    { stat = "ivrpgmeltyblood", amount = melt and 1 or 0}
  })
  status.setPrimaryDirectives(melt and "?scalenearest=0.5" or "")
  mcontroller.controlParameters(melt and not status.statPositive("ivrpgshapeshifting") and self.transformedMovementParameters or {})
  status.setStatusProperty("ivrpgmeltyblood", melt)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 8 or not (world.entityCurrency(self.id, "classtype") == 2 or world.entityCurrency(self.id, "classtype") == 3) then
    effect.expire()
  end
end

function reset()
  status.clearPersistentEffects("ivrpgmeltyblood")
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end