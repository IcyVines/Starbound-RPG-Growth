function init()
  status.setPersistentEffects("rogueweakenstats", {
  	{stat = "poisonResistance", amount = -.5},
  	{stat = "bleedMultiplier", amount = 2}
  })
  effect.setParentDirectives("fade=FFFFFF=0.25?border=2;89A04E;384220")
end

function update(dt)
  
end

function uninit()
	status.clearPersistentEffects("rogueweakenstats")
end