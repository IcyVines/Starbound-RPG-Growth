function init()
  script.setUpdateDelta(0)
  effect.addStatModifierGroup({
    {stat = "protection", amount = 5},
    {stat = "protection", effectiveMultiplier = 1.2}
  })
end