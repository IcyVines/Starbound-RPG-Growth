function init()
  effect.addStatModifierGroup({
  	{stat = "poisonResistance", amount = -0.5},
  	{stat = "bleedResistance", amount = -0.5}
  })
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;89A04E;384220")
end

function update(dt)
  
end

function uninit()
end