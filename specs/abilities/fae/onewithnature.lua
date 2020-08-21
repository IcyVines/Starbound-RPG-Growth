require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
end


function update(dt)


  if daytimeCheck() and not undergroundCheck() then
    status.setPersistentEffects("ivrpgonewithnature", {
      {stat = "maxEnergy", baseMultiplier = 1.25},
      {stat = "energyRegenBlockTime", amount = -0.25}
    })
  else
    status.clearPersistentEffects("ivrpgonewithnature")
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 3 or world.entityCurrency(self.id, "classtype") ~= 5 then
    effect.expire()
  end
end

function reset()
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpgonewithnature")
end

function uninit()
  reset()
end

function daytimeCheck()
  return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end
