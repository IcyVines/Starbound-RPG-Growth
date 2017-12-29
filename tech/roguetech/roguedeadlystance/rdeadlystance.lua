function init()
  status.setPersistentEffects("roguedeadlystance", {
  	{stat = "poisonResistance", amount = .5},
  	{stat = "physicalResistance", amount = .5},
  	{stat = "grit", amount = 1},
  })
  --effect.setParentDirectives("fade=FFFFFF=0.25?border=1;89A04E;384220")
end

function update(dt)
  
end

function uninit()
	status.clearPersistentEffects("roguedeadlystance")
end