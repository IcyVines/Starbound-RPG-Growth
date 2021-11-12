require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
end


function update(dt)
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 8 or not (world.entityCurrency(self.id, "classtype") == 5 or world.entityCurrency(self.id, "classtype") == 6) then
    effect.expire()
  end

end

function uninit()

end
