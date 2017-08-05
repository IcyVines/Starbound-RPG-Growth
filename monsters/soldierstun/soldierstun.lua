function init()
  effect.setParentDirectives("fade=FFFFFF=0.25?border=2;e89819;a36809")
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.0,
      speedModifier = 0.0,
      airJumpModifier = 0.0
    })
end

function uninit()
end
