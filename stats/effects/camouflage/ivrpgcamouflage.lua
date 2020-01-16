function init()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  local invuln = config.getParameter("invulnerable", false)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({
    {stat = "ivrpgstealth", amount = 1},
    {stat = "invulnerable", amount = invuln and 1 or 0}
  })
  script.setUpdateDelta(0)
end
