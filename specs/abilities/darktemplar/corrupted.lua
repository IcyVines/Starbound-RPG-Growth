require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  effect.setParentDirectives("fade=80709510=0.75")
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  self.interval = effect.duration()/5
  self.prevdur = effect.duration()
end

function update(dt)
  if self.prevdur - effect.duration() > self.interval then
    self.prevdur = effect.duration()
    for i,id in ipairs(world.entityQuery(mcontroller.position(), 5)) do
      if world.entityAggressive(id) then
        world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "demonic", 4, self.id)
      end
    end
  end
end

function uninit()
end
