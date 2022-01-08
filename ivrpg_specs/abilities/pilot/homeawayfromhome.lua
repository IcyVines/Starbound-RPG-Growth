require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  effect.addStatModifierGroup({
    {stat = "ivrpg_homeawayfromhome", amount = 1}
  })
end


function update(dt)
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 6 then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("ivrpg_homeawayfromhome")
end
