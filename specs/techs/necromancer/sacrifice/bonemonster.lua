require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  effect.addStatModifierGroup({
    {stat = "holyResistance", amount = -1}
  })
end

function update(dt)
end

function uninit()
	status.modifyResourcePercentage("health", -1)
end
