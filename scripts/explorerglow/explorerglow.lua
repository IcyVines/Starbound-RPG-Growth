function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", config.getParameter("particles", true))
  sb.logInfo("Explorer Glow Lua")
end

function update(dt)
  
end

function uninit()
  
end
