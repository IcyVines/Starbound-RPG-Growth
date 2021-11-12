
function init()
  self.id = effect.sourceEntity()
  local alpha = math.floor(config.getParameter("alpha", 0.25) * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({
    {stat = "ivrpgstealth", amount = 1},
    {stat = "invulnerable", amount = 1}
  })
end

function update(dt)
  if not status.overConsumeResource("energy", 5 * dt) then
    weaken()
    effect.expire()
  end
end

function weaken()
  status.setPersistentEffects("ivrpgquasarweaken", {
    {stat = "energyRegenPercentageRate", effectiveMultiplier = 0.5}
  })
end