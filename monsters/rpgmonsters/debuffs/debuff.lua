function init()
  local effectConfig = config.getParameter("effects", {})
  local directives = config.getParameter("directives", "")
  local modifierConfig = config.getParameter("modifiers", {})
  effect.setParentDirectives(directives)
  effect.addStatModifierGroup(effectConfig)
end

function update(dt)
  mcontroller.controlModifiers(modifiers)
  --[[mcontroller.controlModifiers({
      groundMovementModifier = 0.5,
      speedModifier = 0.65,
      airJumpModifier = 0.80
    })]]
end

function uninit()

end