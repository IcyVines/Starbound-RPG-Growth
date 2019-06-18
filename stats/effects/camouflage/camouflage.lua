function init()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({{stat = "ivrpgstealth", amount = 1}})
  script.setUpdateDelta(0)
end
