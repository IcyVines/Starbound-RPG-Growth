require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  effect.setParentDirectives("fade=80709510=0.25?scalenearest=0.5?scalenearest=2")
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  self.interval = 0.5
  self.timer = 0
end

function update(dt)
  self.timer = self.timer + dt
  if self.timer > self.interval then
    for _,id in ipairs(enemyQuery(mcontroller.position(), 30, {withoutEntityId = entity.id()}, self.id, true)) do
      world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "demonic", math.max(status.stat("maxHealth") / 50, 4), self.id)
    end
    self.timer = 0
  end
end

function uninit()
end
