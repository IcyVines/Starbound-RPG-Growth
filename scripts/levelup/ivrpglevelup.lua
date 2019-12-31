function init()
  script.setUpdateDelta(5)
  status.setResourcePercentage("health", 1.0)
  status.setResourcePercentage("energy", 1.0)
  status.setResourcePercentage("food", 1.0)
  --activateVisualEffects()
end

function update(dt)
  animator.setSoundPosition("level", {0,0})
  if effect.duration() == 3 then
    activateVisualEffects()
  end
end

function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.stopAllSounds("level")
  animator.playSound("level")
  --animator.burstParticleEmitter("statustext")

  world.spawnProjectile("invisibleprojectile", mcontroller.position(), entity.id(), {0,0}, true, {timeToLive = 0, damageType = "NoDamage", actionOnReap = {
    {
      action = "particle",
      specification = {
        text =  "Level " .. tostring(math.floor(math.sqrt(world.entityCurrency(entity.id(), "experienceorb")/100))),      -- place your text here, mind the quotes. I did some text construction off-board as you can see.
        color = {90, 190, 20, 255},
        destructionAction = "shrink",
        destructionTime =  0.5,
        layer = "front",
        position = {0,1},
        size = 0.8,  
        approach = {0,10},
        initialVelocity = {0,6},
        finalVelocity = {0,3},
        -- variance = {initialVelocity = {3,10}},  -- 'jitter' of included parameter
        angularVelocity = 0,                                   
        flippable = false,
        timeToLive = 0.5,
        rotation = 0,
        type = "text"
      }
    } 
  }})

  for x = -1,1 do
  	for y = -1,1 do
  		if x == 0 and y == 0 then else world.spawnProjectile("levelupparticle", mcontroller.position(), entity.id(), {x,y}, true) end
  	end
  end
end


function uninit()
  
end
