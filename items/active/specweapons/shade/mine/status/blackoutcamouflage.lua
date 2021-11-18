function init()
  self.id = effect.sourceEntity()
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  local alpha = math.floor(config.getParameter("alpha", 0.25) * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({
    {stat = "ivrpgstealth", amount = 1},
    {stat = "physicalResistance", amount = 3},
    {stat = "energyRegenPercentageRate", effectiveMultiplier = 0},
    {stat = "powerMultiplier", effectiveMultiplier = 0.5}
  })
end