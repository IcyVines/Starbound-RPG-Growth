function init()
  effect.setParentDirectives("border=1;00AA00;00AA00")

  status.addEphemeralEffect("weakpoison", effect.duration())
  effect.addStatModifierGroup({
    {stat = "maxHealth", effectiveMultiplier = 0.75}
  })
end

function update(dt)
  
end

function uninit()

end
