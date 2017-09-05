function init()
  status.setResourcePercentage("health", 1.0)
  status.setResourcePercentage("energy", 1.0)
  activateVisualEffects()
end

function update(dt)
end

function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  animator.playSound("level")

  for x = -1,1 do
  	for y = -1,1 do
  		if x == 0 and y == 0 then else world.spawnProjectile("levelupparticle", mcontroller.position(), entity.id(), {x,y}, true) end
  	end
  end
end


function uninit()
  
end
