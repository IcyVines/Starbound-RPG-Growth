require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
end


function update(dt)
  local targetIds = enemyQuery(mcontroller.position(), 20, {}, self.id)
  if targetIds then
    for _,id in ipairs(targetIds) do
      world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgsoulconversionstatus", 1, self.id)
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 9 or (world.entityCurrency(self.id, "classtype") ~= 2 and world.entityCurrency(self.id, "classtype") ~= 6) then
    effect.expire()
  end

end

function uninit()

end
