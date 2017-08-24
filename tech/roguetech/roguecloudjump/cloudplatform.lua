require "/scripts/rails.lua"

function init()
  mcontroller.setRotation(0)
  vehicle.setInteractive(false)
  self.timer = config.getParameter("liveTime", 5)
  --animator.setParticleEmitterOffsetRegion("cloudParticles", mcontroller.localBoundBox())
  animator.setParticleEmitterEmissionRate("cloudParticles", self.timer/3)
  animator.setParticleEmitterActive("cloudParticles", true)
end

function update(dt)
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    return
  end

  if self.timer > 0 then
    --animator.setParticleEmitterEmissionRate("cloudParticles", 2.0/self.timer)
    self.timer = math.max(0, self.timer - dt)
    if self.timer == 0 then
      vehicle.destroy() 
    end
  end
end
