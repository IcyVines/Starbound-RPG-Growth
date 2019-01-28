require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  --animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  --animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(10)

  self.colors = config.getParameter("colors", {})
  self.priorities = config.getParameter("priorities", {})
  self.id = entity.id()

  --self.healingRate = 1.0 / config.getParameter("healTime", 60)
end

function update(dt)
  --While Underground, gain +10 Armor, +10% Physical Resistance, and +20% Fall Damage Resistance.
  if undergroundCheck() then
    status.setPersistentEffects("ivrpgminerstatus", {
        {stat = "protection", amount = 10},
        {stat = "physicalResistance", amount = 0.1},
        {stat = "fallDamageMultiplier", effectiveMultiplier = 0.8}
    })
  else
    reset()
  end

  if status.statusProperty("ivrpgprofessionpassive", false) then
    animator.setLightActive("ores", true)
    checkOres()
  else
    animator.setLightActive("ores", false)
  end
end

function uninit()
  reset()
end

function reset()
  status.clearPersistentEffects("ivrpgminerstatus")
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end

function checkOres()
  local range = 10
  local srsq = 100
  local mod = "none"
  local priority = -1
  for x = -range, range, 1 do
    for y = -range, range, 1 do
      local distSquared = x ^ 2 + y ^ 2
      local position = {x + mcontroller.xPosition(), y + mcontroller.yPosition()}
      if distSquared <= srsq then
        fMod = world.mod(position, "foreground")
        bMod = world.mod(position, "background")

        local newPriority = self.priorities[fMod]
        if newPriority and newPriority > priority then
          priority = newPriority
          mod = fMod
        end

        local newPriority = self.priorities[bMod]
        if newPriority and newPriority > priority then
          priority = newPriority
          mod = bMod
        end
      end
    end
  end

  local lightColor = copy(self.colors[mod] or self.colors["none"])
  local alphaMod = (status.resource("energy") / status.stat("maxEnergy"))^0.6
  for i=1,3 do
    lightColor[i] = lightColor[i] * alphaMod
  end
  animator.setLightColor("ores", lightColor)

end