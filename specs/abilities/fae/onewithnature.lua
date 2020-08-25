require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
end


function update(dt)

  local blocks = {world.material(vec2.add(mcontroller.position(), {-1,-2}), "foreground"), world.material(vec2.add(mcontroller.position(), {-1,-3}), "foreground"), world.material(vec2.add(mcontroller.position(), {0,-3}), "foreground"), world.material(vec2.add(mcontroller.position(), {1,-3}), "foreground"), world.material(vec2.add(mcontroller.position(), {1,-2}), "foreground")}
  local mods = {world.mod(vec2.add(mcontroller.position(), {-1,-2}), "foreground"), world.mod(vec2.add(mcontroller.position(), {-1,-3}), "foreground"), world.mod(vec2.add(mcontroller.position(), {0,-3}), "foreground"), world.mod(vec2.add(mcontroller.position(), {1,-3}), "foreground"), world.mod(vec2.add(mcontroller.position(), {1,-2}), "foreground")}
  local onDirt = false

  for _,mat in ipairs(blocks) do
    if mat then
      if string.find(mat, "dirt") then
        onDirt = true
        break
      end
    end
  end

  for _,mod in pairs(mods) do
    if mod then
      if string.find(mod, "grass") then
        onDirt = true
        break
      end
    end
  end

  local solarPower = daytimeCheck() and not undergroundCheck()

  status.setPersistentEffects("ivrpgonewithnature", {
    {stat = "maxEnergy", baseMultiplier = solarPower and 1.25 or 1},
    {stat = "energyRegenBlockTime", amount = solarPower and -0.25 or 0},
    {stat = "powerMultiplier", baseMultiplier = onDirt and 1.25 or 1}
  })

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
