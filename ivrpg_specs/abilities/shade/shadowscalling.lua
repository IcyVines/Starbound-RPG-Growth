require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
end


function update(dt)

  local light = getLight()
  if status.statPositive("ivrpgstealth") then
    status.addEphemeralEffect("regeneration1", 0.1)
  end

  if light <= 25 then
    status.setPersistentEffects("ivrpgshadowscalling", {
      {stat = "maxHealth", baseMultiplier = 1.25}
    })
  else
    status.setPersistentEffects("ivrpgshadowscalling", {
      {stat = "maxHealth", baseMultiplier = 0.75},
      {stat = "energyRegenBlockTime", amount = 0.5}
    })
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 2 or world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end


function reset()
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpgshadowscalling")
end

function uninit()
  reset()
end
